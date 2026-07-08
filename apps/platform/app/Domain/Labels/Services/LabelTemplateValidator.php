<?php

namespace App\Domain\Labels\Services;

use Illuminate\Validation\ValidationException;

class LabelTemplateValidator
{
    public const ELEMENT_TYPES = [
        'text', 'binding_text', 'barcode', 'qr', 'image', 'line', 'rectangle',
    ];

    public function validate(array $template, string $tenantId): array
    {
        foreach (['widthMm', 'heightMm', 'elements'] as $required) {
            if (! array_key_exists($required, $template)) {
                throw ValidationException::withMessages(['template_json' => "Missing {$required}."]);
            }
        }

        if (! is_array($template['elements'])) {
            throw ValidationException::withMessages(['template_json' => 'Elements must be an array.']);
        }

        foreach ($template['elements'] as $index => $element) {
            $this->validateElement($element, $index);
        }

        if (collect($template['elements'])->where('type', 'barcode')->count() > 1) {
            throw ValidationException::withMessages(['template_json.elements' => 'Only one barcode element is allowed per label template.']);
        }

        return $this->warnings($template, $tenantId);
    }

    public function warnings(array $template, string $tenantId): array
    {
        $warnings = [];
        $bindingKeys = app(LabelBindingRegistry::class)->keys($tenantId);
        $width = (float) $template['widthMm'];
        $height = (float) $template['heightMm'];
        $elements = $template['elements'] ?? [];

        foreach ($elements as $index => $element) {
            $x = (float) ($element['x'] ?? 0);
            $y = (float) ($element['y'] ?? 0);
            $w = (float) ($element['width'] ?? 0);
            $h = (float) ($element['height'] ?? 0);

            if ($x < 0 || $y < 0 || ($x + $w) > $width || ($y + $h) > $height) {
                $warnings[] = ['type' => 'out_of_bounds', 'element' => $element['key'] ?? $index];
            }

            if (($element['bindingKey'] ?? null) && ! in_array($element['bindingKey'], $bindingKeys, true)) {
                $warnings[] = ['type' => 'missing_binding', 'element' => $element['key'] ?? $index, 'bindingKey' => $element['bindingKey']];
            }

            if (($element['style']['fontSize'] ?? 0) > 18 && $w < 25) {
                $warnings[] = ['type' => 'font_size_suggestion', 'element' => $element['key'] ?? $index];
            }
        }

        if (collect($elements)->where('type', 'barcode')->count() > 1) {
            $warnings[] = ['type' => 'single_barcode_only'];
        }

        for ($i = 0; $i < count($elements); $i++) {
            for ($j = $i + 1; $j < count($elements); $j++) {
                if ($this->overlaps($elements[$i], $elements[$j])) {
                    $warnings[] = ['type' => 'overlap', 'elements' => [$elements[$i]['key'] ?? $i, $elements[$j]['key'] ?? $j]];
                }
            }
        }

        return $warnings;
    }

    private function validateElement(array $element, int $index): void
    {
        if (! in_array($element['type'] ?? null, self::ELEMENT_TYPES, true)) {
            throw ValidationException::withMessages(["template_json.elements.{$index}.type" => 'Unsupported label element type.']);
        }

        foreach (['x', 'y', 'width', 'height'] as $number) {
            if (! is_numeric($element[$number] ?? null)) {
                throw ValidationException::withMessages(["template_json.elements.{$index}.{$number}" => 'Position and size values are required.']);
            }
        }
    }

    private function overlaps(array $a, array $b): bool
    {
        return ! (
            ((float) $a['x'] + (float) $a['width']) <= (float) $b['x'] ||
            ((float) $b['x'] + (float) $b['width']) <= (float) $a['x'] ||
            ((float) $a['y'] + (float) $a['height']) <= (float) $b['y'] ||
            ((float) $b['y'] + (float) $b['height']) <= (float) $a['y']
        );
    }
}
