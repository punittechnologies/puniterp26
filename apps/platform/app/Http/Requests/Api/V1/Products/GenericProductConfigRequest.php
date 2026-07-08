<?php

namespace App\Http\Requests\Api\V1\Products;

use Illuminate\Foundation\Http\FormRequest;

class GenericProductConfigRequest extends FormRequest
{
    public function rules(): array
    {
        return ['*' => ['present']];
    }
}
