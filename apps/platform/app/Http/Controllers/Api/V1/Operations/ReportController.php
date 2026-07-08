<?php

namespace App\Http\Controllers\Api\V1\Operations;

use App\Http\Controllers\Controller;
use App\Models\Dispatch;
use App\Models\InventoryTransaction;
use App\Models\ProductionTransaction;
use App\Support\TenantContext;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function production(Request $request, TenantContext $tenantContext)
    {
        $rows = ProductionTransaction::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->when($request->filled('from'), fn ($query) => $query->whereDate('captured_at', '>=', $request->date('from')))
            ->when($request->filled('to'), fn ($query) => $query->whereDate('captured_at', '<=', $request->date('to')))
            ->orderByDesc('captured_at')
            ->limit((int) $request->integer('limit', 1000))
            ->get(['serial_number', 'barcode_value', 'product_id', 'variant_id', 'gross_weight', 'tare_weight', 'net_weight', 'piece_quantity', 'unit', 'status', 'captured_at']);

        return $this->respond($request, 'production-report', [
            'serial_number', 'barcode_value', 'product_id', 'variant_id', 'gross_weight', 'tare_weight', 'net_weight', 'piece_quantity', 'unit', 'status', 'captured_at',
        ], $rows->map->toArray()->all());
    }

    public function inventory(Request $request, TenantContext $tenantContext)
    {
        $rows = InventoryTransaction::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->orderByDesc('occurred_at')
            ->limit((int) $request->integer('limit', 1000))
            ->get(['product_id', 'variant_id', 'barcode_value', 'transaction_type', 'weight_quantity', 'piece_quantity', 'reference_type', 'reference_id', 'occurred_at']);

        return $this->respond($request, 'inventory-ledger', [
            'product_id', 'variant_id', 'barcode_value', 'transaction_type', 'weight_quantity', 'piece_quantity', 'reference_type', 'reference_id', 'occurred_at',
        ], $rows->map->toArray()->all());
    }

    public function dispatch(Request $request, TenantContext $tenantContext)
    {
        $rows = Dispatch::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->when($request->filled('from'), fn ($query) => $query->whereDate('confirmed_at', '>=', $request->date('from')))
            ->when($request->filled('to'), fn ($query) => $query->whereDate('confirmed_at', '<=', $request->date('to')))
            ->orderByDesc('confirmed_at')
            ->limit((int) $request->integer('limit', 1000))
            ->get(['dispatch_number', 'customer_id', 'status', 'vehicle_number', 'driver_name', 'transporter', 'total_weight', 'total_pieces', 'confirmed_at']);

        return $this->respond($request, 'dispatch-report', [
            'dispatch_number', 'customer_id', 'status', 'vehicle_number', 'driver_name', 'transporter', 'total_weight', 'total_pieces', 'confirmed_at',
        ], $rows->map->toArray()->all());
    }

    private function respond(Request $request, string $filename, array $columns, array $rows)
    {
        $format = $request->query('format');

        if ($format === 'pdf') {
            return response($this->pdf($filename, $columns, $rows), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="'.$filename.'.pdf"',
            ]);
        }

        if ($format === 'xlsx') {
            return response($this->xlsx($filename, [$columns, ...array_map(fn ($row) => array_map(fn ($column) => $row[$column] ?? null, $columns), $rows)]), 200, [
                'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                'Content-Disposition' => 'attachment; filename="'.$filename.'.xlsx"',
            ]);
        }

        if ($format !== 'csv') {
            return response()->json(['columns' => $columns, 'data' => $rows]);
        }

        return new StreamedResponse(function () use ($columns, $rows): void {
            $handle = fopen('php://output', 'w');
            fputcsv($handle, $columns);
            foreach ($rows as $row) {
                fputcsv($handle, array_map(fn ($column) => $row[$column] ?? null, $columns));
            }
            fclose($handle);
        }, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="'.$filename.'.csv"',
        ]);
    }

    private function pdf(string $title, array $columns, array $rows): string
    {
        $lines = [strtoupper(str_replace('-', ' ', $title)), 'Generated: '.now()->format('Y-m-d H:i'), implode(' | ', $columns)];
        foreach (array_slice($rows, 0, 45) as $row) {
            $lines[] = implode(' | ', array_map(fn ($column) => (string) ($row[$column] ?? ''), $columns));
        }
        $content = '';
        $y = 800;
        foreach ($lines as $index => $line) {
            $size = $index === 0 ? 13 : 7;
            $content .= 'BT /F1 '.$size.' Tf 28 '.$y.' Td ('.$this->pdfEscape($line).") Tj ET\n";
            $y -= $index === 0 ? 22 : 13;
            if ($y < 36) {
                break;
            }
        }

        return $this->pdfDocument($content);
    }

    private function pdfDocument(string $content): string
    {
        $objects = [
            '<< /Type /Catalog /Pages 2 0 R >>',
            '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
            '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
            '<< /Length '.strlen($content)." >>\nstream\n".$content.'endstream',
            '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
        ];
        $pdf = "%PDF-1.4\n";
        $offsets = [0];
        foreach ($objects as $index => $object) {
            $offsets[] = strlen($pdf);
            $pdf .= ($index + 1)." 0 obj\n".$object."\nendobj\n";
        }
        $xref = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n0000000000 65535 f \n";
        foreach (array_slice($offsets, 1) as $offset) {
            $pdf .= str_pad((string) $offset, 10, '0', STR_PAD_LEFT)." 00000 n \n";
        }

        return $pdf.'trailer << /Root 1 0 R /Size '.(count($objects) + 1)." >>\nstartxref\n".$xref."\n%%EOF";
    }

    private function pdfEscape(string $text): string
    {
        return str_replace(['\\', '(', ')'], ['\\\\', '\(', '\)'], mb_substr($text, 0, 145));
    }

    private function xlsx(string $sheetName, array $rows): string
    {
        $tmp = tempnam(sys_get_temp_dir(), 'xlsx_');
        $zip = new \ZipArchive;
        $zip->open($tmp, \ZipArchive::OVERWRITE);
        $zip->addFromString('[Content_Types].xml', '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>');
        $zip->addFromString('_rels/.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>');
        $zip->addFromString('xl/_rels/workbook.xml.rels', '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>');
        $zip->addFromString('xl/workbook.xml', '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="'.$this->xmlEscape(mb_substr($sheetName, 0, 31)).'" sheetId="1" r:id="rId1"/></sheets></workbook>');
        $zip->addFromString('xl/worksheets/sheet1.xml', $this->worksheetXml($rows));
        $zip->close();
        $content = file_get_contents($tmp);
        unlink($tmp);

        return $content;
    }

    private function worksheetXml(array $rows): string
    {
        $xml = '<?xml version="1.0" encoding="UTF-8"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>';
        foreach ($rows as $rowIndex => $row) {
            $xml .= '<row r="'.($rowIndex + 1).'">';
            foreach (array_values($row) as $columnIndex => $value) {
                $cell = chr(65 + $columnIndex).($rowIndex + 1);
                $xml .= '<c r="'.$cell.'" t="inlineStr"><is><t>'.$this->xmlEscape((string) $value).'</t></is></c>';
            }
            $xml .= '</row>';
        }

        return $xml.'</sheetData></worksheet>';
    }

    private function xmlEscape(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_XML1, 'UTF-8');
    }
}
