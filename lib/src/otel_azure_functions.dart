// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_azure_functions_suppression.dart';

const _tracerName = 'dartastic_otel_libs_azure_functions';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AzureFunctionsResult {
  const AzureFunctionsResult({
    this.functionApp,
    this.functionName,
    this.region,
    this.plan,
    this.runtime,
    this.runtimeVersion,
    this.triggerKind,
    this.invocationId,
    this.coldStart,
    this.durationMs,
    this.gbSeconds,
    this.executionResult,
    this.alwaysOn,
    this.maxConcurrent,
    this.scaleInstanceCount,
    this.durableInstanceId,
    this.durableRuntimeStatus,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// Function App name.
  final String? functionApp;
  final String? functionName;

  /// `eastus`, `westus2`, ...
  final String? region;

  /// `Consumption`, `Premium`, `Dedicated`, `FlexConsumption`,
  /// `Container`.
  final String? plan;

  /// `dotnet`, `dotnet-isolated`, `node`, `python`, `java`, `powershell`,
  /// `custom`.
  final String? runtime;
  final String? runtimeVersion;

  /// `http`, `timer`, `queue`, `service_bus`, `event_hub`, `event_grid`,
  /// `blob`, `cosmos_db`, `signalr`, `kafka`, `rabbitmq`, `sql`,
  /// `redis`, `dapr`, `durable.activity`, `durable.orchestrator`,
  /// `durable.entity`.
  final String? triggerKind;

  /// Per-invocation correlation id (`x-ms-execution-id`).
  final String? invocationId;

  final bool? coldStart;
  final int? durationMs;

  /// Gigabyte-seconds consumed (Consumption / FlexConsumption billing).
  final double? gbSeconds;

  /// `Success`, `Failure`, `Cancelled`.
  final String? executionResult;

  final bool? alwaysOn;
  final int? maxConcurrent;

  /// Number of scale-out instances at invocation time.
  final int? scaleInstanceCount;

  // ── Durable Functions ──────────────────────────────────────────
  final String? durableInstanceId;

  /// `Running`, `Completed`, `ContinuedAsNew`, `Failed`, `Canceled`,
  /// `Terminated`, `Pending`, `Suspended`.
  final String? durableRuntimeStatus;

  /// Function-app management error code.
  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;
}

class AzureFunctionsCallResult<T> {
  const AzureFunctionsCallResult({required this.value, this.result});
  final T value;
  final AzureFunctionsResult? result;
}

/// Wraps an Azure Functions call in a CLIENT span. [operation] is one of
/// `invoke.http`, `invoke.adminHostCall`, `host.status`, `host.ping`,
/// `host.scale`, `functions.list`, `functions.get`, `functions.invoke`,
/// `functionApp.create`, `functionApp.delete`, `functionApp.update`,
/// `functionApp.restart`, `functionApp.swap`,
/// `appSettings.list`, `appSettings.update`,
/// `keys.list`, `keys.create`, `keys.delete`,
/// `secrets.create`, `secrets.delete`, `secrets.list`,
/// `durable.start`, `durable.terminate`, `durable.signal`,
/// `durable.purge`, `durable.getStatus`, `deployment.zipDeploy`,
/// `deployment.kuduDeploy`, `kudu.command`.
Future<T> tracedAzureFunctions<T>({
  required String operation,
  required Future<AzureFunctionsCallResult<T>> Function() invoke,
}) async {
  if (azureFunctionsInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'azure_functions',
    'rpc.method': operation,
    'azure_functions.operation': operation,
  };

  final span = _tracer().startSpan(
    'azure_functions $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.functionApp != null) {
        extras.add(OTel.attributeString(
          'azure_functions.function_app',
          res.functionApp!,
        ));
      }
      if (res.functionName != null) {
        extras.add(OTel.attributeString(
          'azure_functions.function.name',
          res.functionName!,
        ));
      }
      if (res.region != null) {
        extras.add(OTel.attributeString(
          'azure_functions.region',
          res.region!,
        ));
      }
      if (res.plan != null) {
        extras.add(OTel.attributeString('azure_functions.plan', res.plan!));
      }
      if (res.runtime != null) {
        extras.add(OTel.attributeString(
          'azure_functions.runtime',
          res.runtime!,
        ));
      }
      if (res.runtimeVersion != null) {
        extras.add(OTel.attributeString(
          'azure_functions.runtime.version',
          res.runtimeVersion!,
        ));
      }
      if (res.triggerKind != null) {
        extras.add(OTel.attributeString(
          'azure_functions.trigger.kind',
          res.triggerKind!,
        ));
      }
      if (res.invocationId != null) {
        extras.add(OTel.attributeString(
          'azure_functions.invocation.id',
          res.invocationId!,
        ));
      }
      if (res.coldStart != null) {
        extras.add(OTel.attributeBool(
          'azure_functions.cold_start',
          res.coldStart!,
        ));
      }
      if (res.durationMs != null) {
        extras.add(OTel.attributeInt(
          'azure_functions.duration_ms',
          res.durationMs!,
        ));
      }
      if (res.gbSeconds != null) {
        extras.add(OTel.attributeDouble(
          'azure_functions.gb_seconds',
          res.gbSeconds!,
        ));
      }
      if (res.executionResult != null) {
        extras.add(OTel.attributeString(
          'azure_functions.execution.result',
          res.executionResult!,
        ));
        if (res.executionResult == 'Failure') {
          span.setStatus(SpanStatusCode.Error, 'Function execution Failure');
        }
      }
      if (res.alwaysOn != null) {
        extras.add(OTel.attributeBool(
          'azure_functions.always_on',
          res.alwaysOn!,
        ));
      }
      if (res.maxConcurrent != null) {
        extras.add(OTel.attributeInt(
          'azure_functions.max_concurrent',
          res.maxConcurrent!,
        ));
      }
      if (res.scaleInstanceCount != null) {
        extras.add(OTel.attributeInt(
          'azure_functions.scale.instance_count',
          res.scaleInstanceCount!,
        ));
      }
      if (res.durableInstanceId != null) {
        extras.add(OTel.attributeString(
          'azure_functions.durable.instance_id',
          res.durableInstanceId!,
        ));
      }
      if (res.durableRuntimeStatus != null) {
        extras.add(OTel.attributeString(
          'azure_functions.durable.runtime_status',
          res.durableRuntimeStatus!,
        ));
        if (res.durableRuntimeStatus == 'Failed' ||
            res.durableRuntimeStatus == 'Terminated') {
          span.setStatus(
            SpanStatusCode.Error,
            'Durable ${res.durableRuntimeStatus}',
          );
        }
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'azure_functions.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Functions ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'azure_functions.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Functions HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
