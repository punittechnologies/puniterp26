<?php

namespace App\Domain\Labels\Services;

use App\Models\AuditLog;
use App\Models\Labeling\LabelTemplate;
use App\Models\Labeling\LabelTemplateElement;
use App\Models\Labeling\LabelTemplateVersion;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class LabelTemplateService
{
    public function __construct(private readonly LabelTemplateValidator $validator) {}

    public function create(array $data, string $tenantId): LabelTemplate
    {
        return DB::transaction(function () use ($data, $tenantId) {
            $warnings = $this->validator->validate($data['template_json'], $tenantId);
            $template = LabelTemplate::query()->create([
                ...$data,
                'tenant_id' => $tenantId,
                'width_mm' => $data['template_json']['widthMm'],
                'height_mm' => $data['template_json']['heightMm'],
                'warnings' => $warnings,
                'active_version' => 1,
                'created_by' => Auth::id(),
            ]);
            $version = $this->version($template, 1, 'Created label template.');
            $this->syncElements($template, $version);
            $this->audit('label_template.created', $template, [], $template->toArray());

            return $template;
        });
    }

    public function update(LabelTemplate $template, array $data): LabelTemplate
    {
        return DB::transaction(function () use ($template, $data) {
            $old = $template->toArray();
            $tenantId = $template->tenant_id;
            $templateJson = $data['template_json'] ?? $template->template_json;
            $warnings = $this->validator->validate($templateJson, $tenantId);
            $nextVersion = $template->active_version + 1;

            $template->fill([
                ...$data,
                'width_mm' => $templateJson['widthMm'],
                'height_mm' => $templateJson['heightMm'],
                'template_json' => $templateJson,
                'warnings' => $warnings,
                'active_version' => $nextVersion,
                'updated_by' => Auth::id(),
            ])->save();

            $version = $this->version($template, $nextVersion, 'Updated label template.');
            $this->syncElements($template, $version);
            $this->audit('label_template.updated', $template, $old, $template->fresh()->toArray());

            return $template->fresh();
        });
    }

    public function duplicate(LabelTemplate $template): LabelTemplate
    {
        return $this->create([
            'name' => $template->name.' Copy',
            'code' => $template->code.'-copy-'.Str::lower(Str::random(4)),
            'scope' => $template->scope,
            'product_id' => $template->product_id,
            'variant_id' => $template->variant_id,
            'is_custom_size' => $template->is_custom_size,
            'is_default' => false,
            'template_json' => $template->template_json,
        ], $template->tenant_id);
    }

    public function archive(LabelTemplate $template): void
    {
        $old = $template->toArray();
        $template->update(['is_archived' => true, 'is_active' => false, 'updated_by' => Auth::id()]);
        $this->audit('label_template.archived', $template, $old, $template->fresh()->toArray());
    }

    public function rollback(LabelTemplate $template, int $version): LabelTemplate
    {
        $target = $template->versions()->where('version', $version)->firstOrFail();

        return $this->update($template, ['template_json' => $target->template_json]);
    }

    public function effective(?string $tenantId, ?string $productId = null, ?string $variantId = null): ?LabelTemplate
    {
        return LabelTemplate::query()
            ->where('is_active', true)
            ->where('is_archived', false)
            ->where(function ($query) use ($tenantId) {
                $query->where('tenant_id', $tenantId)->orWhereNull('tenant_id');
            })
            ->where(function ($query) use ($productId, $variantId) {
                $query
                    ->when($variantId, fn ($query) => $query->orWhere(fn ($q) => $q->where('scope', 'variant')->where('variant_id', $variantId)))
                    ->when($productId, fn ($query) => $query->orWhere(fn ($q) => $q->where('scope', 'product')->where('product_id', $productId)))
                    ->orWhere(fn ($q) => $q->where('scope', 'tenant')->where('is_default', true))
                    ->orWhere(fn ($q) => $q->where('scope', 'system')->where('is_default', true));
            })
            ->orderByRaw("case scope when 'variant' then 1 when 'product' then 2 when 'tenant' then 3 else 4 end")
            ->first();
    }

    private function version(LabelTemplate $template, int $version, string $summary): LabelTemplateVersion
    {
        LabelTemplateVersion::query()
            ->where('label_template_id', $template->id)
            ->update(['status' => 'superseded']);

        return LabelTemplateVersion::query()->create([
            'tenant_id' => $template->tenant_id,
            'label_template_id' => $template->id,
            'version' => $version,
            'status' => 'active',
            'template_json' => $template->template_json,
            'change_summary' => ['summary' => $summary],
            'warnings' => $template->warnings,
            'activated_at' => now(),
            'created_by' => Auth::id(),
            'approved_by' => Auth::id(),
        ]);
    }

    private function syncElements(LabelTemplate $template, LabelTemplateVersion $version): void
    {
        LabelTemplateElement::query()->where('label_template_id', $template->id)->delete();

        foreach ($template->template_json['elements'] ?? [] as $index => $element) {
            LabelTemplateElement::query()->create([
                'tenant_id' => $template->tenant_id,
                'label_template_id' => $template->id,
                'label_template_version_id' => $version->id,
                'element_key' => $element['key'] ?? 'element_'.$index,
                'type' => $element['type'],
                'binding_key' => $element['bindingKey'] ?? null,
                'x' => $element['x'],
                'y' => $element['y'],
                'width' => $element['width'],
                'height' => $element['height'],
                'layer_order' => $element['layerOrder'] ?? $index,
                'style' => $element['style'] ?? null,
                'format' => $element['format'] ?? null,
                'visibility' => $element['visibility'] ?? null,
                'prefix' => $element['prefix'] ?? null,
                'suffix' => $element['suffix'] ?? null,
            ]);
        }
    }

    private function audit(string $action, LabelTemplate $template, array $old, array $new): void
    {
        AuditLog::query()->create([
            'tenant_id' => $template->tenant_id,
            'user_id' => Auth::id(),
            'action' => $action,
            'auditable_type' => $template::class,
            'auditable_id' => $template->id,
            'old_values' => $old,
            'new_values' => $new,
        ]);
    }
}
