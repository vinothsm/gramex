---
title: Data Processing in the Browser
prefix: lodash
...

[TOC]

## Why process data in the browser?

**Most datasets we render are small** (<100MB). JavaScript is quite fast for this.

**JavaScript is interactive**, and can re-render transformed data without
hitting the server. (For example, if you want to sort, group by different
fields, and the data is small enough.)

So increasingly, we use the browser to process small scale data.

This tutorial introduces [Lodash](https://lodash.com/) -- a versatile utility
that helps process data in the browser.

## Import Lodash

On Gramex, Lodash is part of the [UI component library](../uicomponents/). Use:

```html
<script src="ui/lodash/lodash.min.js"></script>
```

Or use a CDN:

```html
<script src="https://cdn.jsdelivr.net/npm/lodash@4.17.11/lodash.min.js"></script>
```

Or use yarn or npm to install locally:

```bash
yarn install lodash   # if you use yarn
npm install lodash    # if you don't use yarn
```

... and include:

```html
<script src="node_modules/lodash/lodash.min.js"></script>
```

## Lodash overview

Every Lodash function starts with an underscore, like `_.<something>()`.
Note: [Lodash is an alternate name for underscore](https://stackoverflow.com/questions/38006384/why-the-name-underscore-or-lodash).

The [Lodash documentation](https://lodash.com/docs/) is a good *reference* for
these functions. But it's not a great tutorial. This guide will help you use
Lodash for *data processing*. (Lodash does things apart from data processing.)

Most *data* in JavaScript is stored as JSON, and is typically structured as:

- Arrays -- either arrays of objects, or arrays of scalars (numbers, strings)
- Objects -- with scalar values, or nested objects

Lodash has functions to process:

- Arrays (filter, group, sort, etc.)
- Objects (extend, merge, set, etc.)
- Strings (template, startsWith, escape, etc.)
- ... and many more -- but we will stick to these.

(Actually, native JavaScript is improving. So
[you might may not](https://github.com/you-dont-need/You-Dont-Need-Lodash-Underscore)
[need Lodash](https://youmightnotneed.com/lodash/).
But like jQuery, it's still a good long-lasting library.)

### Iteratees

Lodash functions that loop through arrays or objects accept an "iteratee". For
example, `_.map(collection, iteratee)` loops through each item in an array or
object. The iteratee can always be:

- **a function**. This always has the signature `(value, key)`.
  <br>For lists like `["a", "b"]`, `value` is `"a"`, `"b"`, ..., and `key` is `0`, `1`, ...
  <br>For objects like `{x: "a"}, {"y": "b"}`, `value` is `"a"`, `"b"`, ..., and `key` is `"x"`, `"y"`, ...

Iteratees may also use specific shorthands. Some commonly used shorthands are:

- the [property](https://lodash.com/docs/#property) shorthand:
    - if the collection has objects as values
      <br>`_.map([{x: 1}, {x: 2}, {x: 3}], 'x')` returns the `x` values, i.e. `[1, 2, 3]`
      <br>This can also be property paths, e.g. `x.y.0.z`, which becomes `item.x.y[0].z`
    - if the collection has arrays or strings as values.
      <br>`_.map(['ab', 'cd', 'ef'], 0)` returns the first elements, i.e. `['a', 'c', 'e']`
- the [matches](https://lodash.com/docs/#matches) shorthand
    - `_.filter(people, {name: 'Alice', gender: 'F'})` returns all females named Alice
- the [matchesProperty](https://lodash.com/docs/#matches) shorthand
    - `_.filter(people, ['birthday', false])` returns all people with missing birthdays

## Common scenarios

For these scenarios, we'll take a few standard datasets.

```js
let people = [
  {id: 101, name: "Alice", gender: 'F', birthday: "20-May", email: "alice@example.org", ...},
  {id: 102, name: "Bob", gender: 'M', birthday: "30-Jun", email: "bob@example.org", ...},
  ... etc ...
]

let bookings = [
  {id: 101, project: "ABC", start_date: "2018-04-01", end_date: "2018-07-31", ...},
  {id: 101, project: "XYZ", start_date: "2018-08-01", end_date: "2018-10-31", ...},
  {id: 102, project: "ABC", start_date: "2018-04-01", end_date: "2018-06-30", ...},
  {id: 102, project: "XYZ", start_date: "2018-07-01", end_date: "2018-10-31", ...},
  ...
]
```

### Create lookups

```js
// Look up people by ID
let people_by_id = _.keyBy(people, 'id')
// people_by_id[101].name == 'Alice'

// Look up people by approximate name
let fingerprint = name => name.toLowerCase().split(/\s+/).sort().join(' ')
let people_by_name = _.keyBy(people, person => fingerprint(person.name))
```

### Sort lists

```js
// Sort array by name
_.orderBy(people, 'name')

// Sort array by name (reversed)
_.orderBy(people, 'name', 'desc')    // JS function

// Sort the array by birthday
_.orderBy(people, person => moment.utc(person.birthday))

// Sort by email domain name
_.orderBy(people, person => person.email.split('@')[1])

// Sort by birthday, then name descending
_.orderBy(people, [person => moment.utc(person.birthday), 'name'], ['asc', 'desc'])

// Sort by inner properties, e.g. attributes of objects or property paths
_.orderBy(people, 'name.length')
```

[_.orderBy](https://lodash.com/docs/#fromPairs) works on objects too, but
returns only the values. Sorting objects *with the keys* is a difficult problem.


### Filter arrays

```js
// Get people whose birthday is filled
_.filter(people, 'birthday')

// Get people whose birthday is NOT filled
_.reject(people, 'birthday')
_.filter(people, ['birthday', false])
_.filter(people, person => !person.birthday)
```

Related methods are:

- [_.dropWhile](https://lodash.com/docs/#dropWhile)
- _.takeWhile

### Filter objects

```js
// Get people whose birthday is filled
_.pickBy(people_by_id, 'birthday')

// Get people whose birthday is NOT filled
_.omitBy(people_by_id, 'birthday')

// Get people whose ID <= 101
_.pickBy(people_by_id, (person, id) => id <= 101)
```

### De-duplicate

```js
// Get unique names
_.uniqBy(people, 'name')

// Get unique lowercase names
_.uniqBy(people, person => person.name.toLowerCase())
```

### Group by

```js
// Group by gender
_.groupBy(people, 'gender')
// Returns {'M': [... list of people...], 'F': [... list of people ...]}

// Group by month of birthday
_.groupBy(people, person => moment.utc(person.birthday).format('MMM'))
// Returns {Jan: [...], Feb: [...], ...}
```

To aggregate after you [groupBy](https://lodash.com/docs/#groupBy), use
[mapValues](https://lodash.com/docs/#mapValues).

```js
// Get the oldest person by gender
let people_by_gender = _.groupBy(people, 'gender')
_.mapValues(people_by_gender, people => _.minBy(people, person => moment.utc(person.birthday)))
```


### Chaining

### Set operations

_.union*
_.inte

```js
_.min([1, 2, 3])
```

### Chaining

    .keyBy(v => fingerprint_name(v.name))
    .value()


### Documentation

Jump to a random example, and check if you will understand it after a month.
(Correct answer: No, you will not.)

Lodash make it easy to write data transformations tersely. But soon, you'll
forget what you did, and more importantly, *why you did it*.

So, add a comment before every data transformation section. Make sure you
explain *why you're doing it*. If required, explain how it works -- but this
is often easy to figure out later.

Here's an example of a descriptive comment.

```js
  // To calculate utilization, only consider the delivery team (subunit is SBUs, CoEs).
  // Ignore interns. Convert into an object. The key is a fuzzy fingerprint of the name.
  // It makes matching names with other datasets easier, if the name is spelt differently.
  let people = _.chain(xhr_people[0])
    .filter(v => v.subunit && v.subunit.match(/SBU|CoE/) && v.job_title && !v.job_title.match(/Intern/))
    .keyBy(v => fingerprint_name(v.name))
    .value()
```


# TODO

- _.pick and _.omit with property paths
- zipObjectDeep


<script src="../ui/moment/min/moment.min.js"></script>
<script>
let people = [
  {id: 101, name: "Alice", gender: 'F', birthday: "20-May", email: "alice@example.org"},
  {id: 102, name: "Bob", gender: 'M', birthday: "30-Jun", email: "bob@example.org"}
]
let bookings = [
  {id: 101, project: "ABC", start_date: "2018-04-01", end_date: "2018-07-31"},
  {id: 101, project: "XYZ", start_date: "2018-08-01", end_date: "2018-10-31"},
  {id: 102, project: "ABC", start_date: "2018-04-01", end_date: "2018-06-30"},
  {id: 102, project: "XYZ", start_date: "2018-07-01", end_date: "2018-10-31"}
]

let people_by_id = _.keyBy(people, 'id')
let fingerprint = name => name.toLowerCase().split(/\s+/).sort().join(' ')
let people_by_name = _.keyBy(people, person => fingerprint(person.name))
</script>
