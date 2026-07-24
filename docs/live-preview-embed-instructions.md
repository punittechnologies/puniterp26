# Punit ERP Live Preview Embed Instructions

Use this live preview on the website homepage so visitors can play with weighing, label printing, inventory and dispatch-style flow.

## File Created

```text
embeds/punit-erp-live-preview.html
```

This is a self-contained demo. It does not need Laravel, database, API, React, or build tools.

## What It Shows

- Live weighing screen
- Product selection
- Product detail selection
- Gross / tare / net weight
- Inventory update
- Barcode label preview
- Save weight action
- Print label action
- Recent weighments
- Cloud sync / scale / printer status badges

## Option 1: Embed With iframe

Upload this file to your website hosting:

```text
punit-erp-live-preview.html
```

Then add this HTML on your homepage:

```html
<iframe
  src="/punit-erp-live-preview.html"
  style="width:100%;height:860px;border:0;border-radius:24px;overflow:hidden;"
  loading="lazy"
  title="Punit ERP Live Preview">
</iframe>
```

## Option 2: WordPress Custom HTML Block

In WordPress:

1. Open homepage editor.
2. Add block: `Custom HTML`.
3. Paste:

```html
<iframe
  src="/punit-erp-live-preview.html"
  style="width:100%;height:860px;border:0;border-radius:24px;overflow:hidden;"
  loading="lazy"
  title="Punit ERP Live Preview">
</iframe>
```

## Option 3: WordPress Shortcode

Add this code in your theme `functions.php` or a small custom plugin:

```php
add_shortcode('punit_erp_preview', function () {
    return '<iframe src="/punit-erp-live-preview.html" style="width:100%;height:860px;border:0;border-radius:24px;overflow:hidden;" loading="lazy" title="Punit ERP Live Preview"></iframe>';
});
```

Then use this shortcode anywhere:

```text
[punit_erp_preview]
```

## Recommended Homepage Section Text

```text
Try Punit ERP Live
Experience how live weighing, barcode label printing, inventory and dispatch work together in one simple factory-ready system.
```

## Notes

- This is a marketing/demo widget, not connected to live ERP data.
- It is safe for public website visitors.
- It works on desktop and mobile.
- For real connected demo, build a separate demo tenant/API with fake data.
