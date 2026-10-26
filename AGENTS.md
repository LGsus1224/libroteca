# AGENTS.md — reglas del proyecto Libroteca

Este archivo lo leen los agentes de código (Claude Code, Codex, etc.) al abrir la carpeta.

## Qué es el proyecto

Libroteca es una app Flutter (Android) donde las personas exploran un catálogo de libros, guardan favoritos en el teléfono, escriben reseñas visibles para toda la comunidad y consultan a un asistente de lectura. Tiene dos partes:

- **App Flutter** (raíz): estado con GetX, HTTP con `dio`, token en `flutter_secure_storage`, favoritos en Hive.
- **Backend** (`backend/`): servidor Node.js sin dependencias externas con autenticación JWT, libros, reseñas y el endpoint `/asistente`, que es el único lugar donde puede vivir la clave de IA.

## Dónde está cada cosa

- `lib/screens/` — pantallas (solo interfaz).
- `lib/controllers/` — estado compartido (controladores GetX).
- `lib/services/` — llamadas HTTP y almacenamiento seguro. `lib/repositories/` — datos locales (Hive).
- `lib/models/`, `lib/utils/`, `lib/widgets/`, `lib/theme/`, `lib/config/`.
- `backend/src/` — rutas, autenticación, persistencia y asistente. `backend/test/` — pruebas de la API.
- `test/` — pruebas de la app.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test
cd backend && npm test
```

Los tres deben terminar sin errores. Si fallan, corrige el código; no desactives el análisis ni borres pruebas.

## Convenciones

- Flujo de un dato: pantalla → controlador GetX → servicio/repositorio → backend. Ninguna pantalla llama a `dio` ni a Hive directamente.
- El estado compartido entre pantallas vive en controladores GetX; `setState` solo para estado local de un formulario.
- Cada pantalla con datos cubre carga, vacío y error con `CargandoView`, `VacioView` y `ErrorView`.
- Todo texto visible va en español neutro. Colores y espaciado salen de `AppTheme`.
- Cambios pequeños y enfocados, con una prueba por cada comportamiento nuevo.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, los registros o este archivo. No leer ni modificar `.env`.
- Poner una clave de un proveedor de IA dentro de la app: solo en variables de entorno del backend.
- Agregar dependencias nuevas sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git push` o crear etiquetas sin que la persona lo pida.
