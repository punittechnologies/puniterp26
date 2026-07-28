<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\FoundationController;
use App\Http\Controllers\Api\V1\Labels\LabelTemplateController;
use App\Http\Controllers\Api\V1\Operations\CustomerController;
use App\Http\Controllers\Api\V1\Operations\InventoryController;
use App\Http\Controllers\Api\V1\Operations\ReportController;
use App\Http\Controllers\Api\V1\Operations\SyncController;
use App\Http\Controllers\Api\V1\Products\ProductBatchController;
use App\Http\Controllers\Api\V1\Products\ProductCategoryController;
use App\Http\Controllers\Api\V1\Products\ProductConfigurationController;
use App\Http\Controllers\Api\V1\Products\ProductController;
use App\Http\Controllers\Api\V1\Products\ProductSyncController;
use App\Http\Controllers\Api\V1\Products\ProductVariantController;
use App\Http\Controllers\Api\V1\Verification\QrVerificationController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function (): void {
    Route::get('health', [FoundationController::class, 'health']);
    Route::post('auth/login', [AuthController::class, 'login']);

    Route::middleware(['auth:sanctum', 'tenant'])->group(function (): void {
        Route::get('auth/me', [AuthController::class, 'me']);
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::get('sync/bootstrap', [FoundationController::class, 'syncBootstrap']);

        Route::get('sync/products', ProductSyncController::class)->middleware('permission:app.login|products.view');
        Route::get('sync/batches', [ProductBatchController::class, 'index'])->middleware('permission:app.login|products.view');
        Route::get('batches', [ProductBatchController::class, 'index'])->middleware('permission:app.login|products.view');
        Route::get('configuration/products', [ProductConfigurationController::class, 'history'])->middleware('permission:configuration.history.view');

        Route::apiResource('product-categories', ProductCategoryController::class)
            ->except(['show'])
            ->middleware('permission:categories.manage');

        Route::apiResource('products', ProductController::class)
            ->middleware('permission:products.view');
        Route::get('products/{product}/variants', [ProductVariantController::class, 'index'])->middleware('permission:variants.manage');
        Route::post('products/{product}/variants', [ProductVariantController::class, 'store'])->middleware('permission:variants.manage');

        Route::get('product-attributes', [ProductConfigurationController::class, 'attributes'])->middleware('permission:attributes.manage');
        Route::post('product-attributes', [ProductConfigurationController::class, 'storeAttribute'])->middleware('permission:attributes.manage');
        Route::get('dynamic-fields', [ProductConfigurationController::class, 'dynamicFields'])->middleware('permission:dynamic_fields.manage');
        Route::post('dynamic-fields', [ProductConfigurationController::class, 'storeDynamicField'])->middleware('permission:dynamic_fields.manage');
        Route::get('units', [ProductConfigurationController::class, 'units'])->middleware('permission:units.manage');
        Route::post('units', [ProductConfigurationController::class, 'storeUnit'])->middleware('permission:units.manage');
        Route::post('unit-conversions', [ProductConfigurationController::class, 'storeConversionRule'])->middleware('permission:conversion_rules.manage');
        Route::post('weight-rules', [ProductConfigurationController::class, 'storeWeightRule'])->middleware('permission:weight_rules.manage');
        Route::post('device-product-config', [ProductConfigurationController::class, 'storeDeviceAssignment'])->middleware('permission:product_device_assignments.manage');

        Route::get('label-templates/bindings', [LabelTemplateController::class, 'bindings'])->middleware('permission:label_templates.manage');
        Route::get('label-templates/effective', [LabelTemplateController::class, 'effective'])->middleware('permission:label_templates.view');
        Route::get('sync/label-templates', [LabelTemplateController::class, 'sync'])->middleware('permission:app.login');
        Route::post('label-templates/app-default', [LabelTemplateController::class, 'appDefault'])->middleware('permission:app.login');
        Route::post('qr/verifications', [QrVerificationController::class, 'store'])->middleware('permission:app.login');
        Route::post('label-templates/{label_template}/duplicate', [LabelTemplateController::class, 'duplicate'])->middleware('permission:label_templates.manage');
        Route::post('label-templates/{label_template}/archive', [LabelTemplateController::class, 'archive'])->middleware('permission:label_templates.manage');
        Route::post('label-templates/{label_template}/rollback', [LabelTemplateController::class, 'rollback'])->middleware('permission:label_templates.rollback');
        Route::get('label-templates/{label_template}/versions', [LabelTemplateController::class, 'versions'])->middleware('permission:label_templates.view');
        Route::apiResource('label-templates', LabelTemplateController::class)
            ->middleware('permission:label_templates.manage');

        Route::apiResource('customers', CustomerController::class)
            ->except(['destroy'])
            ->middleware('permission:customers.manage');
        Route::get('inventory/summary', [InventoryController::class, 'summary'])->middleware('permission:inventory.view');
        Route::get('inventory/ledger', [InventoryController::class, 'ledger'])->middleware('permission:inventory.view');
        Route::get('reports/production', [ReportController::class, 'production'])->middleware('permission:reports.view');
        Route::get('reports/inventory', [ReportController::class, 'inventory'])->middleware('permission:reports.view');
        Route::get('reports/dispatch', [ReportController::class, 'dispatch'])->middleware('permission:reports.view');
        Route::post('sync/inward_session', [SyncController::class, 'inwardSession'])->middleware('permission:production.capture');
        Route::post('sync/production_transaction', [SyncController::class, 'production'])->middleware('permission:production.capture');
        Route::delete('sync/production_transaction/{clientId}', [SyncController::class, 'deleteProduction'])->middleware('permission:production.capture');
        Route::get('dispatch/barcodes/{barcode}', [SyncController::class, 'barcode'])->middleware('permission:dispatch.confirm');
        Route::get('sync/dispatches', [SyncController::class, 'dispatches'])->middleware('permission:dispatch.confirm');
        Route::post('sync/dispatch', [SyncController::class, 'dispatch'])->middleware('permission:dispatch.confirm');
    });
});
