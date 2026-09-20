// lib/features/diagrama_editor/presentation/pages/diagram_editor_page.dart
//
// Pantalla del editor de diagramas.
//
// Layout:
//   ┌──────────────────────────────────────┐
//   │  Header (nombre + acciones)          │
//   ├─────────────────────────────┬────────┤
//   │                             │        │
//   │   Canvas (InteractiveViewer)│ Sidebar│
//   │   + Toolbar flotante        │ (props)│
//   │                             │        │
//   └─────────────────────────────┴────────┘

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/sync/sync_status_widget.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../generacion_codigo/presentation/widgets/generar_backend_sheet.dart';
import '../../../ia_assistant/presentation/widgets/ia_panel.dart';
import '../../../proyectos/presentation/providers/proyecto_detalle_provider.dart';
import '../../domain/clase_uml_entity.dart';
import '../providers/diagrama_provider.dart';
import '../providers/websocket_provider.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/diagram_canvas.dart';
import '../widgets/editor_sidebar.dart';
import '../widgets/relation_creation_overlay.dart';

class DiagramEditorPage extends ConsumerStatefulWidget {
  final int diagramaId;

  const DiagramEditorPage({super.key, required this.diagramaId});

  @override
  ConsumerState<DiagramEditorPage> createState() => _DiagramEditorPageState();
}

class _DiagramEditorPageState extends ConsumerState<DiagramEditorPage> {
  final _transformationController = TransformationController();

  bool _iaPanelAbierto = false;
  bool _sidebarAbierto = true;  // Por defecto abierto en tablets, cerrado en móvil

  /// Tab activa del sidebar. Se puede cambiar desde los botones del AppBar.
  EditorTab _sidebarTab = EditorTab.propiedades;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Limpiar cualquier estado previo del diagrama anterior
      ref.read(diagramaProvider.notifier).limpiar();

      // Cargar el nuevo diagrama
      _cargar();

      // Activar WebSocket de colaboración
      ref.read(webSocketControllerProvider(
        WebSocketArgs(diagramaId: widget.diagramaId),
      ));
    });
    // Escuchar cambios del modo del editor y mostrar un SnackBar
    ref.listenManual<ModoEditor>(
      diagramaProvider.select((s) => s.modo),
      (previous, next) {
        if (previous == next) return;
        final mensaje = _textoModo(next);
        if (mensaje.isEmpty || !mounted) return;

        //if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.brand600,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    // NO tocar `ref` acá: el widget ya está desmontado.
    // El limpiar() se hace en el initState del próximo diagrama.
    super.dispose();
  }

  Future<void> _cargar() async {
    await ref.read(diagramaProvider.notifier).cargar(widget.diagramaId);

    // Cargar proyecto del diagrama para saber el rol del usuario
    final diagrama = ref.read(diagramaProvider).diagrama;
    if (diagrama != null) {
      ref.read(proyectoDetalleProvider.notifier).cargar(diagrama.idProyecto);
    }

    // Ajustar la vista para que las clases queden visibles
    _ajustarVistaInicial();
  }

  void _ajustarVistaInicial() {
    final clases = ref.read(diagramaProvider).clases;
    if (clases.isEmpty) return;

    // Calcular el bounding box de todas las clases
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final c in clases) {
      if (c.posX < minX) minX = c.posX;
      if (c.posY < minY) minY = c.posY;
      if (c.posX + 200 > maxX) maxX = c.posX + 200; // ancho aprox
      if (c.posY + 100 > maxY) maxY = c.posY + 100; // alto aprox
    }

    // Mover la cámara para centrar el bounding box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;

      final scale = 0.8;
      final offsetX = (screenWidth - (maxX - minX) * scale) / 2 - minX * scale;
      final offsetY = (screenHeight - (maxY - minY) * scale) / 2 - minY * scale;

      final m = Matrix4.identity()
        ..translate(offsetX, offsetY)
        ..scale(scale);
      _transformationController.value = m;
    });
  }

  // ==================================================================
  // Crear clase al hacer tap en el canvas (si modo addClass)
  // ==================================================================
  Future<void> _onCanvasTap(Offset canvasPosition) async {
    final modo = ref.read(diagramaProvider).modo;
    if (modo != ModoEditor.addClass) return;

    final nombre = await _pedirNombreClase();
    if (nombre == null || nombre.trim().isEmpty) return;

    try {
      await ref.read(diagramaProvider.notifier).crearClase(
            nombre: nombre.trim(),
            posX: canvasPosition.dx - 100,
            posY: canvasPosition.dy - 20,
          );
      ref.read(diagramaProvider.notifier).setModo(ModoEditor.select);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear clase: $e')),
        );
      }
    }
  }

  Future<String?> _pedirNombreClase() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva clase'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Paciente, HistoriaClinica...',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // ==================================================================
  // Zoom
  // ==================================================================
  void _zoomIn() {
    final m = _transformationController.value.clone();
    m.scale(1.2);
    _transformationController.value = m;
  }

  void _zoomOut() {
    final m = _transformationController.value.clone();
    m.scale(0.8);
    _transformationController.value = m;
  }

  void _fitView() {
    _transformationController.value = Matrix4.identity();
  }

  // ==================================================================
  // Cambiar de tab del sidebar (desde el AppBar)
  // ==================================================================
  void _abrirTab(EditorTab tab) {
    setState(() {
      _iaPanelAbierto = false; // Cerrar IA si estaba abierta
      _sidebarTab = tab;
    });
  }

  // ==================================================================
  // Render
  // ==================================================================
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagramaProvider);
    final modo = state.modo;
    final diagrama = state.diagrama;

    // Rol del usuario en el proyecto
    final usuario = ref.watch(usuarioActualProvider);
    final proyectoDetalle = ref.watch(proyectoDetalleProvider);
    final miRol = (usuario != null && proyectoDetalle.proyecto != null)
        ? proyectoDetalle.proyecto!.rolDeUsuario(usuario.id)
        : null;
    final soloLectura = miRol?.value == 'LECTOR';

    final screenWidth = MediaQuery.of(context).size.width;
final esPantallaChica = screenWidth < 600;

// Si es pantalla chica y no abriste el sidebar manualmente, no mostrarlo
final mostrarSidebar = !esPantallaChica || _sidebarAbierto;

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (diagrama == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Diagrama')),
        body: const Center(
          child: Text('No se pudo cargar el diagrama'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface950,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diagrama.nombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              'UML ${diagrama.versionUml} · v${diagrama.numeroVersion}'
              '${soloLectura ? ' · Solo lectura' : ''}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.surface400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(
            AppRoutes.proyectoDetalle(diagrama.idProyecto),
          ),
        ),
        actions: [
          // Indicador de sincronización
          SyncStatusWidget(diagramaId: widget.diagramaId),

          // Versiones
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Versiones',
            onPressed: () => _abrirTab(EditorTab.versiones),
          ),

          // Comentarios
          IconButton(
            icon: const Icon(Icons.chat_outlined),
            tooltip: 'Comentarios',
            onPressed: () => _abrirTab(EditorTab.comentarios),
          ),

          // Menú desplegable
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'exportar':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exportar (próximamente)')),
                  );
                  break;
                case 'importar':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Importar (próximamente)')),
                  );
                  break;
                case 'generar':
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface900,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) =>
                        GenerarBackendSheet(diagramaId: widget.diagramaId),
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'exportar', child: Text('Exportar XMI')),
              PopupMenuItem(value: 'importar', child: Text('Importar XMI')),
              PopupMenuItem(
                value: 'generar',
                child: Text('Generar backend'),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // -------- Canvas --------
          Expanded(
            child: Stack(
              children: [
                DiagramCanvas(
                  controller: _transformationController,
                  onCanvasTap: soloLectura ? (_) {} : _onCanvasTap,
                ),

                // Overlay para crear relaciones
                if (!soloLectura) const RelationCreationOverlay(),

                // Toolbar
                if (!soloLectura)
                  Positioned(
                    left: 16,
                    top: 16,
                    child: CanvasToolbar(
                      modo: modo,
                      onSelect: () => ref
                          .read(diagramaProvider.notifier)
                          .setModo(ModoEditor.select),
                      onAddClass: () => ref
                          .read(diagramaProvider.notifier)
                          .setModo(ModoEditor.addClass),
                      onAddRelation: () => ref
                          .read(diagramaProvider.notifier)
                          .setModo(ModoEditor.addRelation),
                      onZoomIn: _zoomIn,
                      onZoomOut: _zoomOut,
                      onFitView: _fitView,
                    ),
                  ),

                // Aviso de modo activo
                /*if (modo != ModoEditor.select)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _textoModo(modo),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  */

                // Botón flotante de IA
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    onPressed: () =>
                        setState(() => _iaPanelAbierto = !_iaPanelAbierto),
                    tooltip: 'Asistente IA',
                    backgroundColor:
                        _iaPanelAbierto ? AppColors.brand600 : null,
                    child: const Icon(Icons.auto_awesome),
                  ),
                ),
                // Botón para abrir/cerrar sidebar (solo en pantalla chica)
          if (esPantallaChica)
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton.small(
                onPressed: () => setState(() => _sidebarAbierto = !_sidebarAbierto),
                tooltip: _sidebarAbierto ? 'Cerrar panel' : 'Abrir panel',
                child: Icon(_sidebarAbierto ? Icons.close : Icons.menu),
              ),
            ),
              ],
            ),
          ),

          // -------- Sidebar derecho --------
          if (mostrarSidebar)
            SizedBox(
            width: 300,
            child: _iaPanelAbierto
                ? IAPanel(
                    proyectoId: diagrama.idProyecto,
                    diagramaId: diagrama.id,
                    onCerrar: () => setState(() => _iaPanelAbierto = false),
                  )
                : EditorSidebar(
                    diagramaId: widget.diagramaId,
                    initialTab: _sidebarTab,
                  ),
          ),
        ],
      ),
    );
  }

  String _textoModo(ModoEditor modo) {
    switch (modo) {
      case ModoEditor.addClass:
        return 'Tocá el lienzo para crear una clase';
      case ModoEditor.addRelation:
        return 'Tocá dos clases para crear una relación';
      case ModoEditor.addInterface:
        return 'Interfaz (próximamente)';
      case ModoEditor.select:
        return '';
    }
  }
}
