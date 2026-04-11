# Evaluator Quickstart

Esta guía está pensada para que un evaluador pueda **levantar, probar y validar** el proyecto con la menor fricción posible.

---

## 1. Preconditions

Antes de empezar, asegurate de tener lo siguiente:

- repositorio clonado y branch `main`
- **Flutter SDK** instalado y disponible en PATH
- **Android device físico** conectado por cable **o** un **emulador Android** levantado
- acceso a internet
- `google-services.json` ya presente en `frontend/android/app/`

> Nota: para evaluación funcional del frontend, el proyecto se conecta a **Firebase/Firestore en la nube**. No hace falta levantar backend local para usar la app.

---

## 2. Frontend setup and run

Desde la raíz del repo:

```bash
cd frontend
flutter pub get
flutter run
```

### Resultado esperado

- la app compila y se instala en el dispositivo o emulador
- abre el dashboard público sin requerir login

---

## 3. Manual evaluation flow

Se recomienda evaluar en este orden.

### 3.1 Public dashboard

**Pasos**
- abrir la app
- verificar que el dashboard cargue noticias públicas
- abrir el detalle de una noticia

**Resultado esperado**
- dashboard visible sin login
- detalle visible sin login

---

### 3.2 Authentication

**Pasos**
- registrar un usuario nuevo o iniciar sesión con uno existente
- probar login con email/password
- probar login con Google
- hacer logout

**Resultado esperado**
- login exitoso
- mensajes de error claros si las credenciales son inválidas
- logout correcto y retorno al dashboard

---

### 3.3 Profile

**Pasos**
- ingresar a perfil
- editar nombre y edad
- subir o cambiar foto
- guardar cambios

**Resultado esperado**
- perfil persistido en Firestore
- foto persistida en Firebase Storage
- datos del autor sincronizados con notas existentes

---

### 3.4 Create draft → publish article

**Pasos**
- crear un borrador desde la sección de authoring
- completar título, contenido e imagen
- publicar la nota

**Resultado esperado**
- el borrador aparece en “Mis notas” y no en dashboard
- al publicar, la nota aparece en dashboard

---

### 3.5 My Notes lifecycle

**Pasos**
- abrir “Mis notas”
- editar una nota existente
- archivar una nota
- reactivar la nota archivada

**Resultado esperado**
- al archivar, desaparece del dashboard
- al reactivar, vuelve a mostrarse

---

### 3.6 Favorites

**Pasos**
- guardar una nota en favoritos desde el detalle
- abrir “Mis favoritos”
- quitar favorito
- opcional: archivar una nota ya favorita desde “Mis notas” y verificar comportamiento

**Resultado esperado**
- favorito persistido por usuario
- visible en “Mis favoritos”
- al quitarlo desaparece
- si la nota se archiva, se oculta de favoritos sin perder el vínculo
- si luego se reactiva, vuelve a aparecer en favoritos

---

## 4. Automated validation

### 4.1 Frontend tests

```bash
cd frontend
flutter test
```

### Resultado esperado

- suite frontend en verde

---

### 4.2 Backend security tests

Aunque la app usa Firebase cloud para la evaluación funcional, las reglas de seguridad se validan con emuladores.

```bash
cd backend
npm install
npm run test:rules
```

### Resultado esperado

- tests de Firestore Rules en verde
- tests de Storage Rules en verde

---

## 5. Fast evaluator checklist

- [ ] `flutter pub get`
- [ ] `flutter run`
- [ ] dashboard público funciona
- [ ] auth funciona
- [ ] draft → publish funciona
- [ ] archive/reactivate funciona
- [ ] favorites funciona
- [ ] `flutter test` en verde
- [ ] `npm run test:rules` en verde

---

## 6. Related docs

- `DocsV2/05-delivery/EVALUATOR_GUIDE.md` — evaluación funcional por feature
- `DocsV2/05-delivery/QUALITY_GATE.md` — comandos y criterios de calidad
- `DocsV2/04-backend/FIREBASE_CONTRACT.md` — contrato de datos
- `DocsV2/04-backend/RULES_AND_INDEXES.md` — reglas e índices
