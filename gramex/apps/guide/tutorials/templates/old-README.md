---
title: Using templates to render data
prefix: templates
...

[TOC]

Templates are a simple, powerful way of converting data into visual stories.

In this tutorial, we will take a real-life dataset and narrate a visual story using g1's template feature.

## Requirements

../quickstart/store-sales.csv

## Introduction

**Objective**: SuperStore wants to understand how their sales has changed, and why. Their sales data looks like this. See the [quickstart](../quickstart/#introduction) to understand the fields.

<div class="raw-data table-responsive" data-src="../data"></div>
<script>
  $('.raw-data').formhandler({pageSize: 5})
</script>

<script type="text/html" class="template">
<p class="mt-3">You can access the full dataset as JSON at <a href="<%= data_url %>"><%= data_url %></a>.</p>
</script>

## Render templates from data

We will use [g1](../../g1/) as the main templating library.

### Load libraries

Create an `index.html` file and import these dependencies.

- [Bootstrap](https://www.jsdelivr.com/package/npm/bootstrap) for the UI components
- [jQuery](https://www.jsdelivr.com/package/npm/jQuery) for DOM manipulation (required by g1)
- [lodash](https://www.jsdelivr.com/package/npm/jQuery) for data crunching (required by g1)
- [numeral](https://www.jsdelivr.com/package/npm/numeral) for formatting numbers
- [g1](https://www.jsdelivr.com/package/npm/g1) for templating. **Note**: `g1` should be loaded *after* jQuery and lodash.

Add this to `index.html`:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.3.1/dist/css/bootstrap.min.css">

<script src="https://cdn.jsdelivr.net/npm/jquery"></script>
<script src="https://cdn.jsdelivr.net/npm/lodash"></script>
<script src="https://cdn.jsdelivr.net/npm/numeraljs"></script>
<script src="https://cdn.jsdelivr.net/npm/g1"></script>
```

### Write code in templates

The [g1](../../g1/) templating library lets you define templates inside
`<template>...</template>` or `<script type="text/html">...</script>`.

When you call `$('body').template()`, it finds all these templates and renders
them, using these rules:

- By default, all text is rendered as-is.
- Anything inside `<%= ... %>` is evaluated as JavaScript and is displayed
- Anything inside `<% ... %>` is evaluated as JavaScript, and not displayed

You can also render specific templates using `$(selector).template()`. For
example, this script renders all templates with `class="tmpl"`.

For example:

<!-- render:html -->
```html
<template class="tmpl">
  <% for (var n=1; n<5; n++) { %>
    <div><%= n %> &times; <%= n %> = <%= n * n %></div>
  <% } %>
</template>
<template>This won't be rendered -- no class="tmpl"</template>
<script>
  $('.tmpl').template()
</script>
```

**Note**: We recommend `<script type="text/html">` instead of `<template>`.
`<template>` requires valid HTML. Templates like `<input <%= required %>>` are
**not** valid HTML, and **won't** work inside `<template>`.

### Pass data from JavaScript

You can pass data to `.template(...)` as an object. For example:

<!-- render:html -->
```html
<template class="data-js">
  x = <%= x %>,                 <!-- "x" must be passed to this template -->
  y = <%= JSON.stringify(y) %>  <!-- "y" must also be passed -->
</template>
<script>
  $('.data-js').template({
    x: 1,           // The template can use the variable "x"
    y: ["a", "b"]   // The template can use the variable "y"
  })
</script>
```

### Pass data from HTML

You can also pass data to templates via `data-*` attributes. These can be
accessed in the templates as the `$data` object. For example:

<!-- render:html -->
```html
<template class="data-html" data-x="1" data-y="['a', 'b']">
  x = <%= $data.x %>,
  y = <%= JSON.stringify($data.y) %>
</template>
<script>
  $('.data-html').template()
</script>
```

The `data-*` attributes are parsed as JSON if they begin with `[` or `{`.

## Render multiple blocks

Let's show SuperStore's total sales as simple KPIs. Here is a sample design:

<div class="row">
  <div class="col-md-4 mb-2">
    <div class="card">
      <div class="card-body text-center">
        <h5 class="card-title text-uppercase">Sales ($)</h5>
        <p class="card-text h1">10,000,000</p>
      </div>
    </div>
  </div>
  <div class="col-md-4 mb-2">
    <div class="card">
      <div class="card-body text-center">
        <h5 class="card-title text-uppercase">Quantity (#)</h5>
        <p class="card-text h1">10,000,000</p>
      </div>
    </div>
  </div>
  <div class="col-md-4 mb-2">
    <div class="card">
      <div class="card-body text-center">
        <h5 class="card-title text-uppercase">Profit ($)</h5>
        <p class="card-text h1">10,000,000</p>
      </div>
    </div>
  </div>
</div>

### Design sample output first

When creating templates, start by designing the output (with dummy data).
Here's single KPI block:

<!-- render:html -->
```html
<div class="row">
  <div class="col-md-4 mb-2">
    <div class="card">
      <div class="card-body text-center">
        <h5 class="card-title text-uppercase">title</h5>
        <p class="card-text h1">value</p>
      </div><!-- .card-body -->
    </div><!-- .card -->
  </div><!-- .col-md-4 -->
</div><!-- .row -->
```

### Convert to a template

Now, let's make these changes:

1. Wrap the repeating block (i.e. the `<div class="col-md-4 mb-2">`) inside a
   `<script type="text/html" data-append="true">` tag to make it a template.
2. Replace `title` with `<%= title %>`
3. Replace `value` with `<%= numeral(value).format('0,0') %>`

Now, `index.html` should has code:

<!-- render:html -->
```html
<div class="row">
  <!-- Wrap the block inside a script tag -->
  <template class="kpi">
    <div class="col-md-4 mb-2">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title text-uppercase"><%= title %></h5>
          <p class="card-text h1"><%= numeral(value).format('0,0') %></p>
        </div><!-- .card-body -->
      </div><!-- .card -->
    </div><!-- .col-md-4 -->
  </template>
</div><!-- .row -->
```

When you add this JavaScript, it renders the template with the actual data.

<!-- render:js -->
```js
$.getJSON(data_url, function (data) {
  $('.kpi').template({ title: 'Sales ($)', value: _.sumBy(data, 'Sales') })
})
```

### Append multiple templates

Add a `data-append="true"` attribute to the template. Every time we call
`.template()`, it creates a new copy by *appending* the result. Otherwise, it
just *replaces* the output.

<!-- render:html -->
```html
<div class="row">
  <!-- Note the data-append="true" below -->
  <template class="kpi2" data-append="true">
    <div class="col-md-4 mb-2">
      <div class="card">
        <div class="card-body text-center">
          <h5 class="card-title text-uppercase"><%= title %></h5>
          <p class="card-text h1"><%= numeral(value).format('0,0') %></p>
        </div><!-- .card-body -->
      </div><!-- .card -->
    </div><!-- .col-md-4 -->
  </template>
</div><!-- .row -->
```

Calling `.template()` with different values appends the template results for
each KPI.

<!-- render:js -->
```js
$.getJSON(data_url, function (data) {
  $('.kpi2').template({ title: 'Sales ($)', value: _.sumBy(data, 'Sales') })
  $('.kpi2').template({ title: 'Quantity (#)', value: _.sumBy(data, 'Quantity') })
  $('.kpi2').template({ title: 'Profit ($)', value: _.sumBy(data, 'Profit') })
})
```

<script src="https://cdn.jsdelivr.net/npm/numeraljs"></script>
<script>
  var data_url = g1.url.parse(location.href).join('../data')
  data_url.hash = ''
  data_url = data_url.toString()
  // Replace "data_url"
  $('*').each(function(){
    $.each(this.childNodes, function() {
      if (this.nodeType === 3) {
        if (this.data.match(/data_url/))
          this.data = this.data.replace(/data_url/, JSON.stringify(data_url))
      }
    })
  })

  $('.template').template()
</script>


# TODO

- Re-using templates through:
  - Appending
  - Sub-templates
- Options
- Animation
- Optional
  - External source
  - Events
