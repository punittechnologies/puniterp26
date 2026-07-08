<?php

namespace App\Http\Controllers\Api\V1\Labels;

use App\Domain\Labels\Services\LabelBindingRegistry;
use App\Domain\Labels\Services\LabelTemplateService;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Labels\LabelTemplateRequest;
use App\Http\Resources\Api\V1\Labels\LabelTemplateResource;
use App\Models\Labeling\LabelTemplate;
use App\Support\TenantContext;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Support\Str;

class LabelTemplateController extends Controller
{
    public function index(TenantContext $tenantContext): AnonymousResourceCollection
    {
        return LabelTemplateResource::collection(LabelTemplate::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->where('is_archived', false)
            ->when(request('scope'), fn ($query, $scope) => $query->where('scope', $scope))
            ->latest()
            ->paginate((int) request('per_page', 15)));
    }

    public function store(LabelTemplateRequest $request, TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource
    {
        return new LabelTemplateResource($service->create($request->validated(), $tenantContext->tenantId()));
    }

    public function show(LabelTemplate $labelTemplate, TenantContext $tenantContext): LabelTemplateResource
    {
        $this->ensureTenant($labelTemplate, $tenantContext);

        return new LabelTemplateResource($labelTemplate);
    }

    public function update(LabelTemplateRequest $request, LabelTemplate $labelTemplate, TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource
    {
        $this->ensureTenant($labelTemplate, $tenantContext);

        return new LabelTemplateResource($service->update($labelTemplate, $request->validated()));
    }

    public function destroy(LabelTemplate $labelTemplate, TenantContext $tenantContext): Response
    {
        $this->ensureTenant($labelTemplate, $tenantContext);
        $labelTemplate->delete();

        return response()->noContent();
    }

    public function duplicate(LabelTemplate $labelTemplate, TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource
    {
        $this->ensureTenant($labelTemplate, $tenantContext);

        return new LabelTemplateResource($service->duplicate($labelTemplate));
    }

    public function archive(LabelTemplate $labelTemplate, TenantContext $tenantContext, LabelTemplateService $service): Response
    {
        $this->ensureTenant($labelTemplate, $tenantContext);
        $service->archive($labelTemplate);

        return response()->noContent();
    }

    public function rollback(LabelTemplate $labelTemplate, TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource
    {
        $this->ensureTenant($labelTemplate, $tenantContext);
        $version = (int) request()->validate(['version' => ['required', 'integer', 'min:1']])['version'];

        return new LabelTemplateResource($service->rollback($labelTemplate, $version));
    }

    public function versions(LabelTemplate $labelTemplate, TenantContext $tenantContext): JsonResponse
    {
        $this->ensureTenant($labelTemplate, $tenantContext);

        return response()->json($labelTemplate->versions()->orderByDesc('version')->get());
    }

    public function bindings(TenantContext $tenantContext, LabelBindingRegistry $registry): JsonResponse
    {
        return response()->json(['bindings' => $registry->bindings($tenantContext->tenantId())]);
    }

    public function effective(TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource|JsonResponse
    {
        $template = $service->effective(
            tenantId: $tenantContext->tenantId(),
            productId: request('product_id'),
            variantId: request('variant_id'),
        );

        return $template ? new LabelTemplateResource($template) : response()->json(['message' => 'No template found.'], 404);
    }

    public function sync(TenantContext $tenantContext): JsonResponse
    {
        $appTemplateCode = $this->appTemplateCode(request());
        $templates = LabelTemplate::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->where('is_active', true)
            ->where('is_archived', false)
            ->where(function ($query) use ($appTemplateCode): void {
                $query
                    ->where('code', 'not like', 'APP-LABEL-%')
                    ->orWhere('code', $appTemplateCode);
            })
            ->get();
        $appDefaultTemplate = $templates->firstWhere('code', $appTemplateCode);

        return response()->json([
            'configurationVersion' => (int) LabelTemplate::query()->where('tenant_id', $tenantContext->tenantId())->max('active_version') ?: 1,
            'appDefaultTemplateId' => $appDefaultTemplate?->id,
            'appDefaultTemplateCode' => $appTemplateCode,
            'templates' => LabelTemplateResource::collection($templates),
            'deleted' => [],
        ]);
    }

    public function appDefault(Request $request, TenantContext $tenantContext, LabelTemplateService $service): LabelTemplateResource
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'template_json' => ['required', 'array'],
            'template_json.widthMm' => ['required', 'numeric', 'min:10', 'max:200'],
            'template_json.heightMm' => ['required', 'numeric', 'min:10', 'max:200'],
            'template_json.elements' => ['required', 'array'],
        ]);

        $code = $this->appTemplateCode($request);
        $payload = [
            'name' => $data['name'],
            'code' => $code,
            'scope' => 'tenant',
            'product_id' => null,
            'variant_id' => null,
            'is_custom_size' => false,
            'is_default' => true,
            'template_json' => $data['template_json'],
        ];

        $template = LabelTemplate::query()
            ->where('tenant_id', $tenantContext->tenantId())
            ->where('code', $code)
            ->first();

        return new LabelTemplateResource(
            $template ? $service->update($template, $payload) : $service->create($payload, $tenantContext->tenantId())
        );
    }

    private function ensureTenant(LabelTemplate $template, TenantContext $tenantContext): void
    {
        abort_unless($template->tenant_id === $tenantContext->tenantId(), 404);
    }

    private function appTemplateCode(Request $request): string
    {
        $user = $request->user();
        $scope = Str::of((string) ($user?->app_username ?: $user?->email ?: $user?->id ?: 'default'))
            ->lower()
            ->replaceMatches('/[^a-z0-9]+/', '-')
            ->trim('-')
            ->limit(70, '');

        return 'APP-LABEL-'.($scope->isEmpty() ? 'default' : $scope);
    }
}
