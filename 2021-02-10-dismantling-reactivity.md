# Dismantling Reactivity

> [!NOTE]  
> The source for the code examples is available at
> <https://github.com/bluebrown/reactive-effects>

Recently I've asked myself how reactivity in frameworks such as Vue is
implemented.

I had already an idea, which involved getters and setters. So my code
looked something like the below at some point.

```javascript
const app = {
  _a: 0,
  get a() {
      return this._a
  },
  set a(val) {
     this._a = val
     this.render()
 },
  render() {
     document.body.textContent = this.a
  }
}
```

This way, every time the setter for the property `a` would be accessed,
the render function would run. That is already somewhat reactive.

But this is kind of ugly and cumbersome. So I decide to do some research
on the topic. I found [this
article](https://medium.com/vue-mastery/the-best-explanation-of-javascript-reactivity-fea6112dd80d).
Although somewhat convoluted, it supported my idea of using
getters/setters.

So I tried myself to implement this a bit more fancy.

The core of this implementation loops over the keys of a data object and
creates new getter/setters pairs for those on the app instance.

```javascript
// create reactive getter/setter pairs from
// object properties returned by the data function
const props = Object.fromEntries(
  Object
    .keys(_data)
    .map(key => [key, {
      get() {
        return _data[key]
      },
      // rerender the app and trigger hooks/watcher
      // is a setter is called
      set(value) {
        const oldVal = _data[key]
        _data[key] = value
        if (mounted) {
          invokeLifeCycleHook(hooks.beforeUpdate)
          shim.render()
          invokeLifeCycleHook(hooks.updated)
          invokeWatcher(key, value, oldVal)
        }
      }
    }])
)
// expose data properties on the shim instance
Object.defineProperties(shim.instance, props)
```

That is already pretty cool and allows writing apps like Vue's option
API. However, upon further investigation, I found out that the linked
article was lying to me.

Here is another interesting bit to read from the official Vue 3 docs
[Reactivity in Depth](https://v3.vuejs.org/guide/reactivity.html).

There are 2 main takeaways from this lesson.

1. The reactive getter/setter pairs are not actually exposed on the
   instance. Instead, an Object Proxy is used.
2. Instead of looking for specific things like watchers and compute
   methods and so on, Vue is using at its core an effect system. More on
   that later.

Let's first take a look at the [Object
Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy).

```javascript
const target = {
  author: "codingsafari",
};

const handler = {};

const proxy = new Proxy(target, handler);
```

We can create a proxy object, and point it to some real object. Then we
can hook into various interaction such as getters and setters. Although
there are many more types of so-called traps.

In the above example the handler is not doing anything but in this
handler you can write any callback for the different traps.

This is also some more explained in the mentioned Vue docs. The provided
example in the Vue docs looks like this.

```javascript
const handler = {
  get(target, property, receiver) {
    track(target, property)
    const value = Reflect.get(...arguments)
    if (isObject(value)) {
      // Wrap the nested object in its own reactive proxy
      return reactive(value)
    } else {
      return value
    }
  },
  set(target, property, value, receiver) {
    trigger(target, property)
    return Reflect.set(...arguments)
  }
}
```

When a getter is called on this proxy, the original getter from that
proxied object is invoked via `Reflect` call. If the return value
happens to be an object, another proxy is created recursively until a
scalar value is returned. Furthermore, it will invoke the `track
function` which will allow tracking which properties have been accessed
while some `effect` was running.

When the setter is accessed, the value on the original object will be
set via `Reflect` call. It also invokes the `trigger` function, which
will be responsible for triggering any `effect` again that has assessed
the property at some point in time.

The other thing that is mentioned in the article is the effect system.
The provided example is this.

```javascript
// Maintain a stack of running effects
const runningEffects = []

const createEffect = fn => {
  // Wrap the passed fn in an effect function
  const effect = () => {
    runningEffects.push(effect)
    fn()
    runningEffects.pop()
  }

  // Automatically run the effect immediately
  effect()
}

// create some effect that runs again
// when someProp changes
createEffect(() => {
   console.log(someProxy.someProp)
})
```

The idea is essentially to put the running effect on the stack before it
runs. Then, when it runs and accesses a property on the proxy, the proxy
can look in the `runningEffect` stack to remember this effect. Later,
when the same property is changed via setter, the effect will run again.

Although in the final API for the end user this effect API isn't exposed
directly, it is powering Vue under the hood.

Basically everything that happens is just an effect, even the render
function.

So the general idea is somewhat clear, but some implementation details
are missing. In the first linked article, it is mentioned that Vue
implements actually classes for this. However, I decided to keep it as
simple as possible, so I will just be using `arrays`, `weak maps` and
`sets`.

```javascript
// Maintain a stack of running effects
const runningEffects = []

// Maintain map of targets and subscribers
const subscribedEffects = new WeakMap()

// Maintain a set of effects that should run on the next tick
const scheduledEffects = new Set()

// put the effect on the stack while running
// so that the proxy knows which effect
// has used the getter/setter
export const createEffect = fn => {
  // Wrap the passed fn in an effect function
  const effect = () => {
    runningEffects.push(effect)
    fn()
    runningEffects.pop()
  }
  // Automatically run the effect immediately
  effect()
}

// Handle tracked getter access
function track(target, prop, value) {
  let subs = subscribedEffects.get(target) || {}
  if (!subs[prop]) subs[prop] = new Set()
  // add running effects to the subscriber set for the given prop
  runningEffects.forEach(fn => subs[prop].add(fn))
  subscribedEffects.set(target, subs)
}

// handle tracked setter access
function trigger(target, prop, value) {
  let subs = subscribedEffects.get(target) || {}
  if (!subs[prop]) return
  // Debounce effects until next tick
  subs[prop].forEach(fn => scheduledEffects.add(fn))
  setTimeout(() => {
    // run scheduled effects on the next tick
    scheduledEffects.forEach(fn => fn())
    // and clear the set afterwards
    scheduledEffects.clear()
  }, 0)
}

// Handle object access
const handler = {
  get(target, prop) {
    const value = Reflect.get(...arguments)
    track(target, prop, value)
    return value !== null && typeof value === 'object'
      ? reactive(value)
      : value;
  },
  set(target, prop) {
    const ok = Reflect.set(...arguments)
    trigger(target, prop, ok)
    return ok
  }
}

// Create reactive proxy object
export function reactive(value) {
  return new Proxy(value, handler)
}
```

Now it is a reactive effect system just like Vue's. To push things a bit
further, I have even implemented `ref` and `toRefs` as known from Vues
composition API.

```javascript
export function ref(value) {
  return reactive({ value })
}

export function toRefs(obj) {
  return Object.fromEntries(
    Object.entries(obj).map(([key, val]) => [key, ref(val)])
  )
}
```

I decided to leave it at this point and not build an abstraction like
Vue on top of it. I actually like the flexibility of it in its current
state. For example, the render function could be anything or there
doesn't even have to be a render function at all.

This image from the Vue 2 documentation may also be help to picture
things. Some details differ a bit, but the general idea is the same.
