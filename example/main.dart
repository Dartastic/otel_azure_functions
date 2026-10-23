// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_azure_functions/otel_azure_functions.dart';

/// Traces Azure Functions calls with OpenTelemetry.
///
/// `otel_azure_functions` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Azure Functions call in
/// [tracedAzureFunctions]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'azure-functions-example');

  // Wraps an Azure Functions call in a CLIENT span.
  final azureFunctionsId = await tracedAzureFunctions<String>(
    operation: 'keys.create',
    invoke: () async {
      // Make the Azure Functions call here, then report what it returned.
      const id = 'azure_functions_8f3a2c';
      return const AzureFunctionsCallResult(
          value: id,
          result: AzureFunctionsResult(
              functionApp: 'example',
              functionName: 'example',
              region: 'eastus',
              plan: 'Consumption',
              runtime: 'dotnet',
              runtimeVersion: '1',
              triggerKind: 'http',
              invocationId: 'invocation_8f3a2c',
              coldStart: true,
              durationMs: 120,
              gbSeconds: 0.5,
              executionResult: 'Success',
              alwaysOn: true,
              maxConcurrent: 1,
              scaleInstanceCount: 3,
              durableInstanceId: 'durableinstance_8f3a2c',
              durableRuntimeStatus: 'Running',
              errorCode: 'example',
              errorMessage: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedAzureFunctions keys.create returned $azureFunctionsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAzureFunctionsInstrumentationAsync.
  await runWithoutAzureFunctionsInstrumentationAsync(
    () => tracedAzureFunctions<String>(
      operation: 'keys.create',
      invoke: () async {
        const id = 'azure_functions_8f3a2c';
        return const AzureFunctionsCallResult(
            value: id,
            result: AzureFunctionsResult(
                functionApp: 'example',
                functionName: 'example',
                region: 'eastus',
                plan: 'Consumption',
                runtime: 'dotnet',
                runtimeVersion: '1',
                triggerKind: 'http',
                invocationId: 'invocation_8f3a2c',
                coldStart: true,
                durationMs: 120,
                gbSeconds: 0.5,
                executionResult: 'Success',
                alwaysOn: true,
                maxConcurrent: 1,
                scaleInstanceCount: 3,
                durableInstanceId: 'durableinstance_8f3a2c',
                durableRuntimeStatus: 'Running',
                errorCode: 'example',
                errorMessage: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
