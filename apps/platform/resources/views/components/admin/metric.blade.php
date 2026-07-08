@props(['label', 'value', 'tone' => 'default'])
<article @class(['metric-card', 'warning' => $tone === 'warning', 'error' => $tone === 'error'])>
    <p>{{ $label }}</p>
    <strong>{{ $value }}</strong>
</article>
