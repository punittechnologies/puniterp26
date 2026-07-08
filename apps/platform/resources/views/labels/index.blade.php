@extends('layouts.admin')

@section('content')
    <livewire:labels.label-designer :template="request()->route('template')" />
@endsection
