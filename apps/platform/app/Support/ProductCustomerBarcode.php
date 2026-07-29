<?php

namespace App\Support;

class ProductCustomerBarcode
{
    public const TYPES = [
        'code128' => 'Code 128',
        'ean13' => 'EAN-13 / GTIN-13',
        'ean8' => 'EAN-8 / GTIN-8',
        'upca' => 'UPC-A / GTIN-12',
        'code39' => 'Code 39',
        'itf14' => 'ITF-14 / GTIN-14',
    ];

    public static function validationMessage(string $type, string $value): ?string
    {
        if (! isset(self::TYPES[$type])) {
            return 'Select a supported customer barcode type.';
        }

        if ($value === '') {
            return 'Enter the customer barcode value.';
        }

        return match ($type) {
            'ean13' => self::validateGtin($value, 13, 'EAN-13'),
            'ean8' => self::validateGtin($value, 8, 'EAN-8'),
            'upca' => self::validateGtin($value, 12, 'UPC-A'),
            'itf14' => self::validateGtin($value, 14, 'ITF-14'),
            'code39' => strlen($value) <= 32 && preg_match('/^[0-9A-Z .\\$\\/+%\\-]+$/', $value)
                ? null
                : 'Code 39 accepts up to 32 uppercase letters, numbers, spaces and - . $ / + %.',
            'code128' => strlen($value) <= 48 && preg_match('/^[\\x20-\\x7E]+$/', $value)
                ? null
                : 'Code 128 accepts up to 48 printable English letters, numbers or symbols.',
            default => null,
        };
    }

    private static function validateGtin(string $value, int $length, string $label): ?string
    {
        if (! preg_match('/^\\d{'.$length.'}$/', $value)) {
            return "{$label} must contain exactly {$length} digits.";
        }

        $digits = array_map('intval', str_split($value));
        $checkDigit = array_pop($digits);
        $sum = 0;
        $weight = 3;
        for ($index = count($digits) - 1; $index >= 0; $index--) {
            $sum += $digits[$index] * $weight;
            $weight = $weight === 3 ? 1 : 3;
        }
        $expected = (10 - ($sum % 10)) % 10;

        return $checkDigit === $expected
            ? null
            : "{$label} check digit is invalid. Expected {$expected}.";
    }
}
