<?php

namespace App\Domain\Products\Services;

use App\Models\ProductConfiguration\DynamicFieldDefinition;
use Illuminate\Validation\ValidationException;

class DynamicFieldValueValidator
{
    public function validate(DynamicFieldDefinition $definition, mixed $value): mixed
    {
        if ($definition->is_required && ($value === null || $value === '')) {
            throw ValidationException::withMessages([$definition->internal_key => 'This field is required.']);
        }

        if ($value === null || $value === '') {
            return null;
        }

        return match ($definition->data_type) {
            'integer' => filter_var($value, FILTER_VALIDATE_INT, FILTER_NULL_ON_FAILURE),
            'decimal' => is_numeric($value) ? (string) $value : throw ValidationException::withMessages([$definition->internal_key => 'Must be a decimal.']),
            'boolean', 'checkbox' => filter_var($value, FILTER_VALIDATE_BOOL, FILTER_NULL_ON_FAILURE),
            'dropdown' => $this->validateOption($definition, $value),
            'multi_select' => $this->validateMultiSelect($definition, $value),
            default => (string) $value,
        };
    }

    private function validateOption(DynamicFieldDefinition $definition, mixed $value): string
    {
        $allowed = collect($definition->dropdown_options ?? [])->pluck('value')->map(fn ($item) => (string) $item);

        if ($allowed->isNotEmpty() && ! $allowed->contains((string) $value)) {
            throw ValidationException::withMessages([$definition->internal_key => 'Invalid option.']);
        }

        return (string) $value;
    }

    private function validateMultiSelect(DynamicFieldDefinition $definition, mixed $value): array
    {
        $values = is_array($value) ? $value : [];
        $allowed = collect($definition->dropdown_options ?? [])->pluck('value')->map(fn ($item) => (string) $item);

        if ($allowed->isNotEmpty() && collect($values)->contains(fn ($item) => ! $allowed->contains((string) $item))) {
            throw ValidationException::withMessages([$definition->internal_key => 'Invalid option.']);
        }

        return $values;
    }
}
