import 'package:flutter/material.dart';

class EstadoOperacion extends StatelessWidget {
  const EstadoOperacion({
    super.key,
    this.loading = false,
    required this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.spa_outlined,
  });
  final bool loading;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator(semanticsLabel: 'Cargando')
          else
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
}

class MensajeOperacion extends StatelessWidget {
  const MensajeOperacion(
    this.message, {
    super.key,
    this.error = false,
    this.onRetry,
  });
  final String? message;
  final bool error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: error ? colors.errorContainer : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message!,
              style: TextStyle(
                color: error
                    ? colors.onErrorContainer
                    : colors.onSecondaryContainer,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Reintentar favoritos'),
              ),
          ],
        ),
      ),
    );
  }
}

class ContenidoPagina extends StatelessWidget {
  const ContenidoPagina({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: child,
    ),
  );
}
