# 🤖 ClaudeBuddy - Widget Flotante Nativo de Tokens para Mac

Un compañero de escritorio flotante nativo de macOS (Swift + SwiftUI) que monitorea en tiempo real el uso de tokens de tus sesiones de **Claude Code** e interactúa con animaciones vivas según lo que Claude esté haciendo en la pantalla.

---

## ✨ Características

1. **📊 Monitoreo de Tokens en Tiempo Real (idéntico a Claude Code)**:
   - **Session (5hr)**: Porcentaje de uso + cuenta regresiva de reseteo (`Resets in 4h`).
   - **Weekly (7 day)**: Porcentaje semanal + cuenta regresiva (`Resets in 2d`).
   - Barra de progreso que cambia a color naranja/rojo de alerta si el uso semanal supera el 85% (ej. 93%).

2. **🤖 Mascota Animada Interactiva (Camina y reacciona en vivo)**:
   - **Caminando / Idle**: Camina de un lado a otro por la pantalla / widget, parpadea y respira suavemente.
   - **💻 Escribiendo código...**: Cuando Claude edita archivos (`Edit`, `Write`), saca una mini laptop cibernética y teclea a toda velocidad con partículas de código flotantes (`{ }`, `</>`, `fn`, `=>`).
   - **🔍 Analizando...**: Cuando Claude lee archivos o ejecuta comandos (`Bash`, `Grep`, `View`), saca una lupa luminosa y escanea.
   - **⚠️ Alerta de Tokens**: Cuando el límite semanal supera el 90%, empieza a sudar con gotas animadas y vibración de pánico.
   - **¡Tócalo!**: Haz clic en el muñeco y dará un brinco divertido.

3. **🪟 Diseño Flotante Nativo Mac**:
   - **Efecto Liquid Glass**: Fondo de cristal esmerilado translúcido (`.ultraThinMaterial`).
   - **Arrastrable a cualquier parte**: Haz clic y arrástralo libremente por la pantalla.
   - **Siempre visible**: Se mantiene flotando sobre tus ventanas de código y terminales sin robar el foco.
   - **Modo Compacto**: Botón en la esquina para reducir el widget a solo el personaje caminando.

4. **⚡️ Icono en la Barra de Menús de macOS**:
   - Muestra el estado y porcentaje semanal directamente en la barra superior (ej. `💻 93%`).
   - Menú contextual para ocultar/mostrar el widget, centrar la posición o salir.

---

## 🚀 Cómo Usarlo

### 1. Iniciar la aplicación
Puedes abrirla desde la terminal:
```bash
open ClaudeBuddy.app
```
O haciendo doble clic sobre `ClaudeBuddy.app` en la carpeta `proyectos-personales` desde el Finder.

### 2. Compilar cambios futuros
Si deseas hacer modificaciones al código Swift:
```bash
cd ClaudeBuddy
swift build -c release
./bundle_app.sh
```

---

## 🛠️ Tecnologías Nativas
- **Lenguaje**: Swift 6
- **UI**: SwiftUI + AppKit (`NSPanel`, `NSStatusItem`)
- **Consumo de recursos**: < 25 MB RAM, ultra ligero y optimizado para Apple Silicon (M1/M2/M3/M4).
