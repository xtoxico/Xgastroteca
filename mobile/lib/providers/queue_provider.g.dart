// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$queueHash() => r'ac1c90d6c7a45a2e9ca0660adcfb75132c80ca00';

/// See also [Queue].
@ProviderFor(Queue)
final queueProvider =
    AutoDisposeAsyncNotifierProvider<Queue, List<QueueJob>>.internal(
      Queue.new,
      name: r'queueProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$queueHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Queue = AutoDisposeAsyncNotifier<List<QueueJob>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
