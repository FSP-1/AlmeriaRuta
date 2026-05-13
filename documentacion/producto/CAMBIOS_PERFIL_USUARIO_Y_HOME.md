# Cambios de Perfil de Usuario y Home

## Objetivo

Este documento recoge los cambios aplicados en la capa de usuario, perfil y Home para evitar duplicidad de código y centralizar la edición de datos personales.

---

## 1. Home

### 1.1 Iconos de la barra superior

En la pantalla principal de Home se dejaron dos acciones visibles:

| Posición | Acción |
|---|---|
| Izquierda | Icono de usuario, abre el perfil |
| Derecha | Icono de salir, cierra sesión |

### 1.2 Flujo de salida de sesión

Al pulsar el icono de salir:

1. Se muestra confirmación.
2. El usuario puede cancelar.
3. Si confirma, se ejecuta `logout()` del `AuthViewModel`.

### 1.3 Archivo implicado

- [lib/features/home/views/home_view.dart](../../V2/almeriarutav02/lib/features/home/views/home_view.dart)

---

## 2. Perfil de usuario

### 2.1 Pantalla nueva

Se creó una pantalla específica de perfil de usuario en lugar de reutilizar Ajustes para editar datos personales.

### 2.2 Funcionalidades incluidas

- Cambiar icono de perfil.
- Ver email y nombre de usuario.
- Editar email y nombre de usuario solo al pulsar un botón de edición.
- Cancelar cambios antes de guardar.
- Cambiar contraseña con contraseña actual + nueva + confirmación.

### 2.3 Comportamiento de edición

Los datos personales no son editables directamente.

Estado por defecto:
- `readOnly = true`
- Solo lectura

Cuando el usuario pulsa editar:
- Se activan los campos.
- Aparecen `Cancelar` y `Guardar`.

### 2.4 Archivos implicados

- [lib/features/auth/views/profile_view.dart](../../V2/almeriarutav02/lib/features/auth/views/profile_view.dart)
- [lib/features/auth/viewmodels/auth_viewmodel.dart](../../V2/almeriarutav02/lib/features/auth/viewmodels/auth_viewmodel.dart)
- [lib/features/auth/services/auth_api_service.dart](../../V2/almeriarutav02/lib/features/auth/services/auth_api_service.dart)

---

## 3. Validaciones compartidas

### 3.1 Objetivo

Evitar repetir validaciones de email, usuario y contraseña en varios formularios.

### 3.2 Archivo reutilizable

- [lib/features/auth/utils/auth_validators.dart](../../V2/almeriarutav02/lib/features/auth/utils/auth_validators.dart)

### 3.3 Validadores centralizados

- `validateLoginIdentifier`
- `validateEmail`
- `validateUsername`
- `validatePassword`
- `validateCurrentPassword`

### 3.4 Resultado

Las pantallas de autenticación y perfil usan la misma lógica de validación y los mismos mensajes base.

---

## 4. Backend de autenticación

### 4.1 Nuevos endpoints

Se añadieron endpoints para actualizar perfil y cambiar contraseña.

| Método | Ruta | Uso |
|---|---|---|
| `PATCH` | `/auth/me` | Actualizar email y nombre de usuario |
| `POST` | `/auth/me/password` | Cambiar contraseña |

### 4.2 Reglas de negocio

- El email no puede repetirse en otro usuario.
- El nombre de usuario no puede repetirse en otro usuario.
- La contraseña nueva debe cumplir las mismas reglas de fortaleza.
- La contraseña actual debe ser correcta para poder cambiarla.
- Si el usuario es invitado, no puede editar perfil ni cambiar contraseña.

### 4.3 Archivos backend implicados

- [backend/auth_mvc/controller.py](../../backend/auth_mvc/controller.py)
- [backend/auth_mvc/service.py](../../backend/auth_mvc/service.py)
- [backend/auth_mvc/repository.py](../../backend/auth_mvc/repository.py)

---

## 5. Mensajes de error

### 5.1 Mensajes exactos

Cuando hay conflicto en BD, el backend devuelve un mensaje específico:

- `El email ya está en uso`
- `El nombre de usuario ya está en uso`

### 5.2 Visualización en la app

Los errores no quedan solo al final de la pantalla.

Ahora se muestran también con `SnackBar` justo al guardar.

---

## 6. Persistencia del icono de usuario

El icono de perfil elegido por el usuario se guarda localmente en `SharedPreferences` y se reutiliza en Home.

Esto permite que el acceso al perfil mantenga una identidad visual sin duplicar lógica de configuración.

---

## 7. Resumen técnico

Este cambio deja la arquitectura más limpia:

1. Home solo navega a perfil o hace logout.
2. Perfil concentra la edición de datos personales.
3. La validación se reutiliza desde un único archivo.
4. El backend valida y devuelve conflictos exactos.
5. La UI muestra errores de forma inmediata.

---

## 8. Resultado final

Se eliminó el uso de Ajustes como punto principal para perfil de usuario y se sustituyó por una pantalla de perfil dedicada, con controles de edición explícitos y mensajes de error precisos.
