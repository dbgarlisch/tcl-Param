# tcl-Param

Provides the *Param* command ensemble.

### Table of Contents
* [Param Commands](#param-commands)
* [Builtin Base Types](#builtin-base-types)
  * [double range](#double)
  * [integer range](#integer)
  * [string range](#string)
  * [enum range](#enum)
* [Custom Base Types](#custom-base-types)
  * [Validators](#validators)


## Param Commands

Commands in this ensemble are accessed as:

```Tcl
Param <cmd> <options>
```
Where,

`cmd` - Is one of the Param command names listed below.

`options` - The cmd dependent options.

### basetype
Creates an application defined basetype. Returns nothing See [Custom Base Types](#custom-base-types).
```Tcl
Param basetype name ?vtorNamespace? ?replace?
```
where,

`name` - The name of the base type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`vtorNamespace` - The optional validator namespace. See [Validators](#validators). (default `name`)

`replace` - If 1, any existing base type definition will be replaced with this one. (default 0)

### getBasetype
Returns the base type of a type definition.
```tcl
Param getBasetype typedefName
```
where,

`typedefName` - The type definition name.

### getBasetypes
Returns a list of all base type names.
```tcl
Param getBasetypes
```

### getLimits
Returns the limits for a given type.
```tcl
Param getLimits type
```
where,

`type` - Is a type definition or base type name.

### getRange
Returns the range for a given type.
```tcl
Param getRange type
```
where,

`type` - Is a type definition or base type name.

### getRangeSignature
Returns the human readable range signature for a given type.
```tcl
Param getRangeSignature type
```
where,

`type` - Is a type definition or base type name.

### getValidator
Returns the validator namespace name for a given type.
```tcl
Param getValidator type
```
where,

`type` - Is a type definition or base type name.

### isBasetype
Returns 1 if `name` is a valid base type name.
```tcl
Param isBasetype name
```
where,

`name` - The name being tested.

### isTypedef
Returns 1 if `name` is a valid type definition name.
```tcl
Param isTypedef name
```
where,

`name` - The name being tested.

### new
Creates a parameter object. Returns the parameter object.
```tcl
Param new type ?val?
```
where,

`type` - An existing type definition name.

`val` - The optional, initial parameter value. The default is type dependent.

### typedef
Creates an application defined parameter data type. A typedef has its own type name and an optional,
basetype-specific value range. When assigning a parameter value, this range will be enforced. A Tcl
`error` is triggered if the assigned value violates the range. The `basetype` must be one of the
[built-in](#base-data-types) or [user defined](#custom-base-types) base types. Returns nothing.
```tcl
Param typedef basetype name ?range? ?replace?
```
where,

`basetype` - One of the [built in](#builtin-base-types) or [user defined](#custom-base-types) base types. See the [basetype](#basetype) command.

`name` - The name of the type being created. An error is triggered if `name` is not unique unless `replace` is set to 1.

`range` - The optional, base type specific range. See [Ranges](#ranges). (default {})

`replace` - If 1, any existing type definition will be replaced with this one. (default 0)


## Builtin Base Types

The Param library supports the `double`, `integer`, `string`, and `enum` base data
types. Base types are used to define application specific types using the `typedef`
command. If appropriate, a corresponding typedef is created for each basetype. Base
typedefs do not have a range and support all valid, type-specific values.

Several base type aliases are also defined.

| Base Type | Aliases         |
| --------- | --------------- |
| `double`  | `real`, `float` |
| `integer` | `int`           |
| `string`  | `text`          |

### Ranges

#### double

Range: `?Inf|?>|=?minLimit ?Inf|?<|=?maxLimit??`

A `double` value supports a `minLimit`, `maxLimit` range. You can control the
value comparison with an optional prefix. The `minLimit` value supports the
*=* (value >= `minLimit`) and *>* (value > `minLimit`) prefixes. The `maxLimit` value
supports the *=* (value <= `maxLimit`) and *<* (value < `maxLimit`) prefixes. If no
prefix is given, *=* is used. Use *Inf* for an unlimited value. If the range is
empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0.0 <= value <= 10.0 |
| {>0 <10}  | 0.0 < value < 10.0   |
| {0}       | 0.0 <= value <= Inf  |
| {0 Inf}   | 0.0 <= value <= Inf  |
| {}        | Inf <= value <= Inf  |

#### integer

Range: `?Inf|minLimit ?Inf|maxLimit??`

An `integer` value supports a `minLimit`, `maxLimit` range. Use *Inf* for an
unlimited value. If the range is empty, `{Inf Inf}` is used.

| Range     | Comparison           |
| --------- | -------------------- |
| {0 10}    | 0 <= value <= 10     |
| {0}       | 0 <= value <= Inf    |
| {0 Inf}   | 0 <= value <= Inf    |
| {}        | Inf <= value <= Inf  |

#### string

Range: `?g|r<CHAR>pattern<CHAR>?i??t? ?minLen ?maxLen???`

A `string` value supports a `pattern` match and `minLen`, `maxLen` range.

The `g` prefix specifies a Tcl *glob* comparison.
The `r` prefix specifies a Tcl *regexp* comparison.

The `pattern` is delimted by a matching `<CHAR>` pair. It can be any character
not used in `pattern`.

The `i` suffix specifies a case-insensitive comparison.
The `t` suffix specifies the value should have leading and trailing whitespace
trimmed before the comparison is performed.

If `minLen` is specified, the value length must be >= `minLen`.
If `maxLen` is specified, the value length must be <= `maxLen`.


| Range              | Comparison                          |
| ------------------ | ----------------------------------- |
| {r/^big.*$/it 4 7} | regexp, nocase, trim, length 4 to 7 |
| {g/big*/it 4 7}    | glob, nocase, trim, length 4 to 7   |

#### enum

Range: `?|<CHAR>?token?=integer? ?|token?=integer??...`

An `enum` value supports a fixed list of token values. Each token has an
asociated integer id. The valid tokens are defined by a delimited list of
`token=integer` pairs. If an integer id is not provided, it will be
assigned the previous token's id value plus one. If there is no previous
token, the id is set to zero.

The default delimiter is the vbar '|' character. The delimiter can be changed
by prefixing the list with a 2-character `|<CHAR>` sequence where `CHAR` is
the new delimiter.

Because all enum typedefs must have a non-empty range, an `enum` typedef is
**not** created.

All `enum` parameters support the `$param getId` command. This returns the
integer id associated with the currently assigned enum token.

| Range                       | Same as                           |
| --------------------------- | --------------------------------- |
| {red\|green\|blue\|alpha}   | {red=0\|green=1\|blue=2\|alpha=3} |
| {red\|green\|blue\|alpha}   | {\|,red,green,blue,alpha}         |
| {top=4\|bot\|left=8\|right} | {top=4\|bot=5\|left=8\|right=9}   |

## Custom Base Types

You can add a custom, user defined base types to the Param library. A base type uses a validator
to implement the base type's behavior. The Param library auto loads all base type
definition files found in the `basetypes` subdirectory that are named
`NAME?-VTOR?.basetype.tcl`. Where `NAME` is the base type's name and `VTOR` is the
validator name used for this base type. If not provided, `VTOR` defaults to `NAME`.
For example:

* *real.basetype.tcl* defines
  * A base type named *real*
  * Using a validator named *real*
* *real-vtor.basetype.tcl* defines
  * A base type named *real*
  * Using a validator named *vtor*

If you do not want to autoload an application defined base type, you can load it
explicitly using the `Param basetype` command.

```tcl
Param basetype name {vtorNamespace {}} {replace 0}
```

### Validators

A validator is a Tcl namespace that provides one or more procs and variables used by the
Param library. The validator namespace must be unique and must exist before the call
to `Param basetype`.

A validator implements the following variable and procs.

```tcl
namespace eval NSPACE {
  variable rangeSignature_ {signature-pattern}                          ;# REQUIRED
  variable createTypedef_ 1                                             ;# OPTIONAL
  variable objectProto_ {commands added to objects of basetype}         ;# OPTIONAL
  variable staticProto_ {static commands added to typedefs of basetype} ;# OPTIONAL
  proc parseRange { range }                                             ;# REQUIRED
  proc validate { value limits }                                        ;# REQUIRED
  proc registerAliases { }                                              ;# OPTIONAL
}
```



<!--

```Tcl
pw::listutils lproduct get <list> ?<list> ...?
```
Returns the product as a list of sub-product lists.
<dl>
  <dt><code>list ?lists ...?</code></dt>
  <dd>One or more lists used used to compute the product.</dd>
</dl>
<br/>

```Tcl
pw::listutils lproduct foreach <varname> <list> ?<list> ...? <body>
```
Each sub-product is passed to the script defined by body using the specified
varname.

<dl>
  <dt><code>varname</code></dt>
  <dd>Name of the sub-product script variable.</dd>
  <dt><code>list ?lists ...?</code></dt>
  <dd>One or more lists used used to compute the product.</dd>
  <dt><code>body</code></dt>
  <dd>The script to execute for each sub-product.</dd>
</dl>
<br/>

### lmutate

```Tcl
pw::listutils lmutate <subcmd> ?<options>?
```
Computes the permutations of a list.

For example, the permutations of `{a b c}` are `{{a b c} {a c b} {b a c} {b c a}
{c b a} {c a b}}`.

<dl>
  <dt><code>subCmd</code></dt>
  <dd>One of get or foreach.</dd>
</dl>
<br/>

```Tcl
pw::listutils lmutate get <list>
```
Returns the permutations as a list of lists.
<dl>
  <dt><code>list</code></dt>
  <dd>The list to mutate.</dd>
</dl>
<br/>

```Tcl
pw::listutils lmutate foreach <varname> <list> <body>
```
Each permutation is passed to the script defined by body using the specified
varname.

<dl>
  <dt><code>varname</code></dt>
  <dd>Name of the permutation script variable.</dd>
  <dt><code>list</code></dt>
  <dd>The list to mutate.</dd>
  <dt><code>body</code></dt>
  <dd>The script to execute for each permutation.</dd>
</dl>
<br/>

### lunion

```Tcl
pw::listutils lunion ?<list> ...?
```
Returns the union of a collection of lists.

For example, the union of `{1 2 3}` and `{a b}` is `{1 2 3 a b}`.
<dl>
  <dt><code>list ...</code></dt>
  <dd>The lists used used to compute the union. If no lists are provided, an
  empty list is returned.</dd>
</dl>
<br/>

### lintersect

```Tcl
pw::listutils lintersect <list> <list> ?<list> ...?
```
Returns the intersection of a collection of lists.

For example, the intersection of `{1 2 3 a}` and `{a 2 z}` is `{a 2}`.
<dl>
  <dt><code>list</code></dt>
  <dd>Two or more lists used used to compute the intersection.</dd>
</dl>
<br/>

### lsubtract

```Tcl
pw::listutils lsubtract <list> <list> ?<list> ...?
```
Returns the left-to-rigth subtraction of a collection of lists.

For example, the subtraction of `{1 2 3 a}` and `{a 2 z}` is `{1 3}`.
<dl>
  <dt><code>list</code></dt>
  <dd>Two or more lists used used to compute the subtraction.</dd>
</dl>
<br/>

### lsymmetricdiff

```Tcl
pw::listutils lsymmetricdiff <list> <list> ?<list> ...?
```
Returns the symmetric difference of a collection of lists. A symmetric
difference of A and B is equivalent to ((A subtract B) union (B subtract A)).

For example, the symmetric difference of `{1 2 3 a}` and `{a 2 z}` is `{1 3 z}`.
<dl>
  <dt><code>list</code></dt>
  <dd>Two or more lists used used to compute the symmetricdifference.</dd>
</dl>
<br/>

### lissubset

```Tcl
pw::listutils lissubset <superlist> <sublist> ?<sublist> ...?
```
Returns true if all sublist lists are a subset of superlist.

For example, `{1 a}` is a sublist of `{1 2 3 a}`.
<dl>
  <dt><code>superlist</code></dt>
  <dd>The list to compare all sublists against.</dd>
  <dt><code>sublist</code></dt>
  <dd>One or more subset lists.</dd>
</dl>
<br/>

### lunique

```Tcl
pw::listutils lunique <list>
```
Returns a copy of list with all duplicates removed.

For example, `lunique {1 a b c 2 3 1 b 9}` returns `{1 a b c 2 3 9}`.
<dl>
  <dt><code>list</code></dt>
  <dd>The list to process.</dd>
</dl>
<br/>

### lremove

```Tcl
pw::listutils lremove <listvarname> <value> ?<options>?
```
Removes the requested value from the list. Returns nothing.

For example, `set lst {a b c d e} ; lremove lst c -sorted` sets `$lst` equal
to `{a b d e}`.
<dl>
  <dt><code>listvarname</code></dt>
  <dd>The list to process.</dd>
  <dt><code>value</code></dt>
  <dd>The value to remove from the list.</dd>
  <dt><code>options</code></dt>
  <dd>Any options supported by `lsearch <options> $lst $value`.</dd>
</dl>
<br/>

### lstitch

```Tcl
pw::listutils lstitch <list1> ?<list2>? ?<repeat>?
```
Returns a single list comprised of alternating values from the `list1` and
`list2`. The returned list will be the same length as `list1` and can be used
as a `dict`.

For example, `lstitch {1 2 3 4} {a b c d}` returns `{1 a 2 b 3 c 4 d}`.
<dl>
  <dt><code>list1</code></dt>
  <dd>The list of dict keys.</dd>
  <dt><code>list2</code></dt>
  <dd>The list of dict values.</dd>
  <dt><code>repeat</code></dt>
  <dd>If 1, `list2` will be repeated as needed to provide values for `list1`.
  If 0, any unmatched keys will have a value of {}. The default is 0.</dd>
</dl>
<br/>

### lshift

```Tcl
pw::listutils lshift <listvarname>
```
Removes the first item from list and returns it. The list is modifed by this
proc. If the list is empty, {} is returned.

For example, `set lst {1 2 3 4} ; lshift $lst` returns `1` and sets `$lst` equal
to `{2 3 4}`.
<dl>
  <dt><code>listvarname</code></dt>
  <dd>The list to process.</dd>
</dl>
<br/>



### pw::listutils Library Usage Examples

#### Example 1

```Tcl
    xxxx
```

[SetWiki]: http://en.wikipedia.org/wiki/Set_%28mathematics%29

-->
