
# Building a Simple SPA Router with the History API

Single-Page Applications (SPAs) rely on routing for seamless navigation
between views without reloading the page. While libraries like React
Router or Vue Router handle routing comprehensively, creating your own
router is a great way to understand the mechanics of the `History API`.  

This article walks through implementing a lightweight, reusable router
using the `History API` and explores how it integrates cleanly into any
application.

## A Quick Overview of the History API

The `History API` provides developers with tools to manipulate the
browser's history stack, enabling dynamic navigation without page
reloads.  

### Key Features

- **`pushState`**: Adds a new entry to the browser's history stack and
  updates the URL in the address bar.  

  ```javascript
  history.pushState({ key: 'value' }, "Title", "/new-path");
  ```

- **`replaceState`**: Updates the current history entry instead of
  creating a new one.  

  ```javascript
  history.replaceState({ key: 'value' }, "Title", "/updated-path");
  ```

- **`onpopstate`**: Detects when users navigate using the browser's back
  or forward buttons.  

  ```javascript
  window.onpopstate = (event) => {
    console.log("State:", event.state);
  };
  ```

These methods allow SPAs to control navigation behavior while
maintaining clean URLs.

### Subtle Differences: `window.location` and `URL`

When working with routing, you'll often interact with `window.location`
and `URL`. While they both represent URLs, they are distinct objects:

- **`window.location`**: A global object tied to the browser’s location,
  with properties like `pathname`, `search`, and `hash`.  
- **`URL`**: A standalone object that adds conveniences like
  `searchParams` for working with query strings.  

For example:

```javascript
const query = "?q=test";

// window.location
console.log(window.location.search); // "?q=test"

// URL
const url = new URL(window.location.href);
console.log(url.searchParams.get("q")); // "test"
```

The `URL` object is often more practical for parsing and manipulating
URLs.

## The Router Implementation

The router intercepts navigation events, updates the URL, and manages
state. It runs the provided hook whenever the URL changes, allowing to
define custom behavior based on the current location. Additionally, it
provides a method to save state associated with a URL. For example, you
can save form data or scroll position when navigating between pages.

```javascript
const router = (hook = console.log) => {
  window.onpopstate = ({ state }) => hook(new URL(window.location.href), state);
  hook(new URL(window.location.href));
  return {
    anchorHandler: e => {
      e.preventDefault();
      window.history.pushState(null, "", e.target.href);
      hook(new URL(e.target.href));
      return false;
    },
    saveState: (state, href = window.location.href) => {
      window.history.pushState(state, "", href);
    }
  };
};
```

> [!NOTE]  
> The anchor handler needs to be attached to all anchor elements in the
> application. This is necessary to prevent the default behavior of
> reloading the page when an anchor is clicked, as well as triggering
> the custom behavior defined in the router.

## Integration into an Application

An example of how to use the router in a simple application. The
application consists of a navigation menu and a main content area. The
router is initialized with a hook that updates the main content area
based on the current URL. The `saveState` method is used to save the
state of an input field when it loses focus. The `anchorHandler` is
attached to all anchor elements to handle navigation without reloading
the page.

```javascript
const locations = {
  "/": (state) => `<h1>Home</h1>
    <p>Type something in this input. If you blur it, it will be saved as state.
      Now you can navigate back and forth to remove/restore it. <br />
      For example, type something and navigate to the about page, 
      then press the back button.
      </p>
      <br />
    <input
      value="${state?.text || ''}"
      onblur="saveState({text: this.value})"
    />
  `,
  "/about": (state) => `<h1>About</h1>`,
  "/contact": (state) => `<h1>Contact</h1>`,
}

pageContent = document.getElementById("page-content");

const { saveState, anchorHandler } = router((location, state) =>
  pageContent.innerHTML = locations[location.pathname]
    ? locations[location.pathname](state)
    : locations["/"](state)
);

document
  .querySelectorAll("a")
  .forEach(a => a.addEventListener("click", anchorHandler));
```

The HTML structure has only minimal content as typically found in a
single-page application:

```html
<nav>
  <ul>
    <li><a href="/">Home</a></li>
    <li><a href="/about">About</a></li>
    <li><a href="/contact">Contact</a></li>
  </ul>
</nav>
<main>
  <div id="page-content"></div>
</main>
```
