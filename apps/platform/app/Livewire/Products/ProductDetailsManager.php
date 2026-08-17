<?php

namespace App\Livewire\Products;

use App\Models\ProductConfiguration\DynamicFieldDefinition;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Livewire\Component;

class ProductDetailsManager extends Component
{
    public string $newFieldName = '';

    public string $newFieldValues = '';

    public bool $newPrintableOnLabel = true;

    public bool $newUseAsWeightDivisor = false;

    public array $fieldNames = [];

    public array $optionInputs = [];

    public function createField(): void
    {
        $data = $this->validate([
            'newFieldName' => ['required', 'string', 'max:255'],
            'newFieldValues' => ['nullable', 'string', 'max:5000'],
            'newPrintableOnLabel' => ['boolean'],
            'newUseAsWeightDivisor' => ['boolean'],
        ]);

        if ($data['newUseAsWeightDivisor'] && ! $this->combinedOptionsArePositiveQuantities($data['newFieldName'], $data['newFieldValues'])) {
            $this->addError('newFieldValues', 'Divided-weight fields must contain only positive quantities, for example 25, 50, 100.');

            return;
        }

        $created = $this->saveFieldWithOptions(
            $data['newFieldName'],
            $data['newFieldValues'],
            (bool) $data['newPrintableOnLabel'],
            (bool) $data['newUseAsWeightDivisor'],
        );

        $this->newFieldName = '';
        $this->newFieldValues = '';
        $this->newPrintableOnLabel = true;
        $this->newUseAsWeightDivisor = false;
        session()->flash('status', $created ? 'Product detail field and values saved.' : 'Existing field found, values merged.');
    }

    public function saveFieldName(string $fieldId): void
    {
        $field = $this->field($fieldId);
        $name = trim((string) ($this->fieldNames[$fieldId] ?? ''));

        $this->validate([
            'fieldNames.'.$fieldId => ['required', 'string', 'max:255'],
        ]);

        $field->update([
            'field_label' => $name,
            'updated_by' => Auth::id(),
        ]);

        session()->flash('status', 'Field name saved.');
    }

    public function addOption(string $fieldId): void
    {
        $field = $this->field($fieldId);
        $input = trim((string) ($this->optionInputs[$fieldId] ?? ''));

        if ($input === '') {
            return;
        }

        $newOptions = $this->optionsFromText($input);

        if ($field->use_as_weight_divisor && ! $this->optionsArePositiveQuantities($newOptions)) {
            $this->addError('optionInputs.'.$fieldId, 'Every divided-weight value must be a positive quantity.');

            return;
        }

        $options = collect($field->dropdown_options ?? [])
            ->merge($newOptions)
            ->unique(fn ($option) => $option['value'] ?? '')
            ->values()
            ->all();

        $field->update([
            'dropdown_options' => $options,
            'updated_by' => Auth::id(),
        ]);

        $this->optionInputs[$fieldId] = '';
        $this->resetErrorBag('optionInputs.'.$fieldId);
        session()->flash('status', count($newOptions) === 1 ? 'Product detail value added.' : count($newOptions).' product detail values added.');
    }

    public function removeOption(string $fieldId, string $optionValue): void
    {
        $field = $this->field($fieldId);
        $options = collect($field->dropdown_options ?? [])
            ->reject(fn ($option) => ($option['value'] ?? '') === $optionValue)
            ->values()
            ->all();

        $field->update([
            'dropdown_options' => $options,
            'updated_by' => Auth::id(),
        ]);
    }

    public function togglePrintable(string $fieldId): void
    {
        $field = $this->field($fieldId);
        $field->update([
            'printable_on_label' => ! $field->printable_on_label,
            'updated_by' => Auth::id(),
        ]);
    }

    public function toggleWeightDivisor(string $fieldId): void
    {
        $field = $this->field($fieldId);
        $next = ! $field->use_as_weight_divisor;

        if ($next && ! $this->optionsArePositiveQuantities($field->dropdown_options ?? [])) {
            $this->addError('optionInputs.'.$fieldId, 'All existing options must be positive quantities before enabling divided weight.');

            return;
        }

        $field->update([
            'use_as_weight_divisor' => $next,
            'updated_by' => Auth::id(),
        ]);
    }

    public function deleteField(string $fieldId): void
    {
        $this->field($fieldId)->delete();
        unset($this->fieldNames[$fieldId], $this->optionInputs[$fieldId]);
        session()->flash('status', 'Product detail field removed.');
    }

    public function render(): mixed
    {
        $fields = DynamicFieldDefinition::query()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('field_label')
            ->get();

        foreach ($fields as $field) {
            $this->fieldNames[$field->id] ??= $field->field_label;
            $this->optionInputs[$field->id] ??= '';
        }

        return view('livewire.products.product-details-manager', [
            'fields' => $fields,
        ]);
    }

    private function field(string $fieldId): DynamicFieldDefinition
    {
        return DynamicFieldDefinition::query()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->findOrFail($fieldId);
    }

    private function nextInternalKey(string $name): string
    {
        $base = Str::of($name)->slug('_')->lower()->replaceMatches('/[^a-z0-9_]/', '')->toString() ?: 'detail';
        if (! preg_match('/^[a-z]/', $base)) {
            $base = 'detail_'.$base;
        }

        $key = $base;
        $counter = 1;

        while (DynamicFieldDefinition::query()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->where('internal_key', $key)
            ->exists()) {
            $counter++;
            $key = $base.'_'.$counter;
        }

        return $key;
    }

    private function baseInternalKey(string $name): string
    {
        $base = Str::of($name)->slug('_')->lower()->replaceMatches('/[^a-z0-9_]/', '')->toString() ?: 'detail';

        return preg_match('/^[a-z]/', $base) ? $base : 'detail_'.$base;
    }

    private function saveFieldWithOptions(string $name, string $values, bool $printableOnLabel, bool $useAsWeightDivisor): bool
    {
        $name = trim($name);
        if ($name === '') {
            return false;
        }

        $key = $this->baseInternalKey($name);
        $field = DynamicFieldDefinition::withTrashed()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->where('internal_key', $key)
            ->first();

        if ($field) {
            if ($field->trashed()) {
                $field->restore();
            }

            $mergedOptions = collect($field->dropdown_options ?? [])
                ->merge($this->optionsFromText($values))
                ->unique(fn ($option) => $option['value'] ?? '')
                ->values()
                ->all();

            $field->update([
                'field_label' => $name,
                'data_type' => 'dropdown',
                'dropdown_options' => $mergedOptions,
                'printable_on_label' => $printableOnLabel,
                'use_as_weight_divisor' => $useAsWeightDivisor,
                'is_active' => true,
                'updated_by' => Auth::id(),
            ]);

            return false;
        }

        DynamicFieldDefinition::query()->create([
            'tenant_id' => $this->tenantId(),
            'field_label' => $name,
            'internal_key' => $key,
            'entity_type' => 'product_variant',
            'data_type' => 'dropdown',
            'dropdown_options' => $this->optionsFromText($values),
            'is_required' => false,
            'visible_in_web' => true,
            'visible_in_flutter' => true,
            'editable_in_flutter' => true,
            'printable_on_label' => $printableOnLabel,
            'use_as_weight_divisor' => $useAsWeightDivisor,
            'visible_in_reports' => true,
            'is_active' => true,
            'created_by' => Auth::id(),
            'updated_by' => Auth::id(),
        ]);

        return true;
    }

    private function optionsFromText(string $text): array
    {
        return collect(preg_split('/[\r\n,]+/', $text))
            ->map(fn ($option) => trim($option))
            ->filter()
            ->unique(fn ($option) => Str::of($option)->slug('_')->toString())
            ->values()
            ->map(fn ($option) => [
                'label' => $option,
                'value' => Str::of($option)->slug('_')->toString(),
            ])
            ->all();
    }

    private function combinedOptionsArePositiveQuantities(string $name, string $values): bool
    {
        $existing = DynamicFieldDefinition::withTrashed()
            ->where('tenant_id', $this->tenantId())
            ->where('entity_type', 'product_variant')
            ->where('internal_key', $this->baseInternalKey($name))
            ->first();
        $options = collect($existing?->dropdown_options ?? [])
            ->merge($this->optionsFromText($values))
            ->values()
            ->all();

        return $this->optionsArePositiveQuantities($options);
    }

    private function optionsArePositiveQuantities(array $options): bool
    {
        return $options !== [] && collect($options)->every(
            fn (array $option): bool => $this->isPositiveQuantity((string) ($option['label'] ?? $option['value'] ?? '')),
        );
    }

    private function isPositiveQuantity(string $value): bool
    {
        return is_numeric(trim($value)) && (float) trim($value) > 0;
    }

    private function tenantId(): string
    {
        $tenantId = Auth::user()?->tenant_id;
        abort_unless($tenantId, 403);

        return $tenantId;
    }
}
