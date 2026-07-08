<?php

namespace App\Domain\Products\Services;

use App\Models\ProductConfiguration\Unit;
use App\Models\ProductConfiguration\UnitConversionRule;
use InvalidArgumentException;

class ConversionCalculator
{
    public function calculate(string $netWeight, UnitConversionRule|array $rule): array
    {
        $data = $rule instanceof UnitConversionRule ? $rule->toArray() : $rule;
        $netWeightInKg = $this->toKg($netWeight, $data['net_weight_unit_factor'] ?? '1');

        $actual = match ($data['method']) {
            'weight_per_piece' => $this->weightPerPiece($netWeight, $data),
            'pieces_per_kg' => bcmul($netWeightInKg, (string) $data['pieces_per_kg'], 8),
            'sample_based' => $this->sampleBased($netWeight, $data),
            default => throw new InvalidArgumentException('Unsupported conversion method.'),
        };

        return [
            'actual_quantity' => $this->normalize($actual, 6),
            'rounded_quantity' => $this->round($actual, $data['rounding_method'] ?? 'none', (int) ($data['decimal_places'] ?? 0)),
        ];
    }

    private function weightPerPiece(string $netWeight, array $data): string
    {
        if (bccomp((string) $data['weight_per_piece'], '0', 8) <= 0) {
            throw new InvalidArgumentException('Weight per piece must be greater than zero.');
        }

        return bcdiv($netWeight, (string) $data['weight_per_piece'], 8);
    }

    private function sampleBased(string $netWeight, array $data): string
    {
        if ((int) $data['sample_piece_count'] <= 0 || bccomp((string) $data['sample_weight'], '0', 8) <= 0) {
            throw new InvalidArgumentException('Sample weight and piece count must be greater than zero.');
        }

        $averagePieceWeight = bcdiv((string) $data['sample_weight'], (string) $data['sample_piece_count'], 8);

        return bcdiv($netWeight, $averagePieceWeight, 8);
    }

    private function toKg(string $weight, string $factor): string
    {
        return bcmul($weight, $factor, 8);
    }

    private function round(string $value, string $method, int $places): string
    {
        $float = (float) $value;
        $rounded = match ($method) {
            'nearest' => round($float, $places),
            'floor' => floor($float * (10 ** $places)) / (10 ** $places),
            'ceil' => ceil($float * (10 ** $places)) / (10 ** $places),
            default => $float,
        };

        return $this->normalize((string) $rounded, $places);
    }

    private function normalize(string $value, int $places): string
    {
        return number_format((float) $value, $places, '.', '');
    }

    public function unitFactorToKg(?Unit $unit): string
    {
        return $unit?->category === 'weight' ? (string) $unit->conversion_factor_to_base : '1';
    }
}
