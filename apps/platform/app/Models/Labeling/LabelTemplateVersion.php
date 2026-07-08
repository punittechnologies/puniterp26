<?php

namespace App\Models\Labeling;

use App\Models\Concerns\HasUuidPrimaryKey;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['tenant_id', 'label_template_id', 'version', 'status', 'template_json', 'change_summary', 'warnings', 'activated_at', 'created_by', 'approved_by'])]
class LabelTemplateVersion extends Model
{
    use HasUuidPrimaryKey;

    protected function casts(): array
    {
        return [
            'version' => 'integer',
            'template_json' => 'array',
            'change_summary' => 'array',
            'warnings' => 'array',
            'activated_at' => 'datetime',
        ];
    }

    public function template(): BelongsTo
    {
        return $this->belongsTo(LabelTemplate::class, 'label_template_id');
    }
}
