import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/models/queue_job.dart';
import 'package:mobile/providers/queue_provider.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cola de Procesamiento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(queueProvider),
          ),
        ],
      ),
      body: queueAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return const Center(child: Text("No hay tareas pendientes."));
          }
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(context, ref, job);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, WidgetRef ref, QueueJob job) {
    Color statusColor;
    switch (job.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        break;
      case 'PROCESSING':
        statusColor = Colors.blue;
        break;
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'FAILED':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.cloud_sync, color: Colors.white),
        ),
        title: Text(
          job.url, // Maybe truncate?
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado: ${job.status} (Intentos: ${job.retryCount})"),
            if (job.status == 'PENDING')
              Text("Reintento: ${job.nextRetryAt}", style: const TextStyle(fontSize: 12)),
            if (job.errorMsg.isNotEmpty)
              Text("Error: ${job.errorMsg}", style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Eliminar tarea"),
                content: const Text("¿Estás seguro de quitar este video de la cola?"),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancelar")),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Eliminar")),
                ],
              ),
            );

            if (confirm == true) {
              await ref.read(queueProvider.notifier).deleteJob(job.id);
            }
          },
        ),
      ),
    );
  }
}
