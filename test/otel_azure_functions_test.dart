// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_azure_functions/otel_azure_functions.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_azure_functions-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('invoke.http records plan + runtime + cold start + GB-sec', () async {
    await tracedAzureFunctions<String>(
      operation: 'invoke.http',
      invoke: () async => const AzureFunctionsCallResult(
        value: 'ok',
        result: AzureFunctionsResult(
          functionApp: 'myapp',
          functionName: 'process-order',
          plan: 'FlexConsumption',
          runtime: 'dotnet-isolated',
          triggerKind: 'http',
          coldStart: true,
          durationMs: 380,
          gbSeconds: 0.19,
          executionResult: 'Success',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('azure_functions invoke.http')!);
    expect(a['azure_functions.plan'], 'FlexConsumption');
    expect(a['azure_functions.cold_start'], true);
    expect(a['azure_functions.gb_seconds'], 0.19);
  });

  test('Failure execution result sets span error', () async {
    await tracedAzureFunctions<String>(
      operation: 'invoke.http',
      invoke: () async => const AzureFunctionsCallResult(
        value: 'ok',
        result: AzureFunctionsResult(executionResult: 'Failure'),
      ),
    );
    expect(
      spans.findSpanByName('azure_functions invoke.http')!.status,
      SpanStatusCode.Error,
    );
  });

  test('durable Failed runtime status sets span error', () async {
    await tracedAzureFunctions<String>(
      operation: 'durable.getStatus',
      invoke: () async => const AzureFunctionsCallResult(
        value: 'ok',
        result: AzureFunctionsResult(
          durableInstanceId: 'inst_1',
          durableRuntimeStatus: 'Failed',
        ),
      ),
    );
    expect(
      spans.findSpanByName('azure_functions durable.getStatus')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutAzureFunctionsInstrumentationAsync(() async {
      await tracedAzureFunctions<String>(
        operation: 'host.status',
        invoke: () async => const AzureFunctionsCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('azure_functions '), isEmpty);
  });
}
