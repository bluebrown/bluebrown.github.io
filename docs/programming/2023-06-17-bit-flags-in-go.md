# Bit Flags in Go

Sometimes options can be expressed using so called bit flags. When using bit
flags, each bit of a given byte is considered on its own to determine if a
specific option is set.

For example we might have a unsigned integer variable to define the combination
of the 3 colors: red, blue and green.

> The `0b` prefix indicates that this is the binary representation of a number.

```go
var rgb uint8 = 0 b 0 0 0
                    │ │ └─ red
                    │ └─── green
                    └───── blue
```

Each color occupies on bit in the integer variable or *bit field*. Above, all
bits are set to 0, so we consider the respective colors to be *unset*.

Now we can use bitwise operators to manipulate individual bits of the rgb
variable.

In order to make it easier to manipulate the bits, we create a constant *bit
mask* for each color.

```go
const (
  red   uint8 = 0b001
  green uint8 = 0b010
  blue  uint8 = 0b100
)
```

## Set a bit

If we want to turn on a particular color, we use the bitwise `OR` operator. This
will leave every bit in `rgb` untouched except for the `red` one. The `red` bit
is *set*  set since the `OR` will set it if it is set in `rgb` or `red`.

```go
rgb = rgb|red // 001
```

## Unset a bit

If we want to turn of a particular bit, we use the bitwise `AND NOT (&^)`. The
`XOR (^)` operator inverts the value of red. So every bit except for the red one
is turn on. Thus, when using te inverted value with the `AND (&)` operator, the
result is that every bit in rgb that was already turned on, remains turned on,
except for the red one. The red bit is always turned of because is is 0 in the
inverted value.

```go
rgb = rgb & ^red // 000
```

## Toggle a bit

If we want to toggle a bit, we use the bitwise `XOR (^)`. In below example we
are toggling the green bit of the rgb variable. This works because every bit
except for the green one is unset in our `green` const. Meaning all bits of
`rgb` except for the green one remain the same. The green one will be set or
unset depending on its current value. If its already set, `XOR` will unset it
because both `rgb` and green have it set. If its not set `XOR` will set it
because the it is set in the `green` variable but not in `rgb`.

```go
rgb = rgb^green // 010
```

## Check wether a bit is set or unset

If we want to check if a particular bit is set, we use the bitwise `AND (&)`
operator, and check if the result is greater than 0.

Because every bit except for the red bit is 0 in our variable `red`, the result
of using the `AND (&)` operator is that every bit except for red is turned to 0.
The red bit itself will only be 1 if it was already 1 in the rgb variable. So we
know if the result is 0, red is not 1 in the rgb variable.

```go
isRed := rgb&red > 0 // true
```

## Iota

Instead of defining each variable manually as uint8 and assigning a value to it,
we can make use if `iota`. First we declare a unit8 type called rgb. Then we use
iota in combination with `left shift (<<)` to define each color bit flag.

The value of `iota` is the ordinal position of the const declaration, starting
at 0. Therefore, in the below example, we set the first const declaration, red,
to 0b001 and shift its position by `iota` which is 0. So effectively we don't
shift at all. On the next declaration, green, we shift 0b001 by 1 resulting in
or 0b10. This pattern repeats until the end of the const block.

```go
const (
 red    rgb = 0b001 << iota // 0b1<<0 = 0b001
 green                      // 0b1<<1 = 0b010
 blue                       // 0b1<<2 = 0b100
)
```

> iota is a predeclared identifier representing the untyped integer ordinal
> number of the current const specification in a (usually parenthesized) const
> declaration. It is zero-indexed.

## Short Hand Assignment

Go supports shorthand assignment using bitwise operators.

For example, instead of:

```go
rgb = rgb|red|blue
```

We can write:

```go
rgb |= red|blue
```

## Example

```go
const (
 red byte = 1 << iota
 green
 blue
)

func configureLighting(flags byte) {
 if flags&red > 0 {
  // turn on red lights
 }
 if flags&green > 0 {
  // turn on green lights
 }
 if flags&blue > 0 {
  // turn on blue lights
 }
}

func main() {
 configureLighting(red | blue)
}
```

## Bitwise Operators

Below is an overview of the bitwise operators in go.

```go
&    bitwise AND            integers
|    bitwise OR             integers
^    bitwise XOR            integers
&^   bit clear (AND NOT)    integers
<<   left shift             integer << integer >= 0
>>   right shift            integer >> integer >= 0
```
