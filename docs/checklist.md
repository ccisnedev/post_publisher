# Post Publisher Checklist

Checklist operativo, en orden exacto, para dejar Post Publisher listo y validar
una publicacion real en LinkedIn desde el CLI.

## Valores oficiales que se deben usar

- Nombre del producto: Post Publisher
- Nombre de la LinkedIn Page: Post Publisher
- Nombre de la LinkedIn App: Post Publisher
- Package Dart: post_publisher
- Dominio publico: https://post-publisher.ccisne.dev
- Privacy Policy URL: https://post-publisher.ccisne.dev/privacy/publisher
- Contact URL: https://post-publisher.ccisne.dev/contact
- Redirect URI del CLI: http://127.0.0.1:8787/callback
- Scopes Fase 1 (perfil personal): openid profile email w_member_social
- Scopes Fase 2 (organizaciones propias): openid profile email w_member_social w_organization_social r_organization_social rw_organization_admin
- LinkedIn API version: 202506

El objetivo final es publicar tanto en el perfil personal como en las paginas
de las organizaciones propias. El paso inicial y la primera validacion real es
el perfil personal (Pasos 1 a 11). La publicacion como organizacion se aborda en
la Fase 2 (Pasos 12 en adelante), porque requiere un producto adicional de
LinkedIn con aprobacion.

## Estado actual ya resuelto

- [x] La app existente post_tool se renombro a Post Publisher
- [x] El package Dart se renombro de linkedin_cli a post_publisher
- [x] Analyze pasa despues del rename del package
- [x] La suite completa de tests pasa despues del rename del package
- [x] Se creo la web minima del producto en code/site
- [x] Se creo el workflow de GitHub Pages

## Paso 1. Crear o confirmar la LinkedIn Page del producto

- [x] Entrar en LinkedIn con la cuenta propietaria
- [x] Crear la LinkedIn Page llamada Post Publisher (id publico post-publisher-cli, organization id 129763971)
- [x] Confirmar que el nombre visible es Post Publisher
- [ ] Añadir descripcion corta del producto
- [ ] Añadir logo cuadrado del producto
- [x] Publicar la page
- [x] Confirmar que la cuenta con la que haras las pruebas tiene permisos de admin sobre esa page

URN de la organizacion para la Fase 2: urn:li:organization:129763971

## Paso 2. Publicar la web minima del producto

- [x] Crear la home minima del producto en code/site
- [x] Crear la privacy policy en code/site/privacy/publisher/index.html
- [x] Crear la pagina de contacto en code/site/contact/index.html
- [x] Crear el archivo CNAME con post-publisher.ccisne.dev
- [x] Añadir el workflow de GitHub Pages
- [x] Crear el repo publico ccisnedev/post_publisher y hacer push a main
- [x] Habilitar Pages con Source = GitHub Actions
- [x] Confirmar que el deploy quedo verde y el sitio carga en https://ccisnedev.github.io/post_publisher/
- [x] Configurar el DNS del Paso 3 antes de fijar el custom domain
- [x] Fijar post-publisher.ccisne.dev como Custom domain (despues del DNS)
- [x] Guardar el custom domain

Nota: con despliegue por GitHub Actions el dominio custom se fija en los
ajustes de Pages (campo cname), no por el archivo CNAME del artefacto. Por eso
el custom domain se deja para despues de tener el DNS del Paso 3, y asi evitar
que el sitio quede inaccesible mientras propaga.

## Paso 3. Configurar DNS del subdominio

- [x] Ir al proveedor DNS de ccisne.dev
- [x] Crear un registro CNAME para post-publisher
- [x] Apuntar ese CNAME a ccisnedev.github.io
- [x] Esperar la propagacion DNS
- [x] Volver a GitHub Pages
- [x] Activar Enforce HTTPS cuando aparezca disponible
- [x] Verificar que abre https://post-publisher.ccisne.dev
- [x] Verificar que abre https://post-publisher.ccisne.dev/privacy/publisher
- [x] Verificar que abre https://post-publisher.ccisne.dev/contact

## Paso 4. Dejar la LinkedIn App completa y consistente

- [ ] Entrar en LinkedIn Developer Portal
- [ ] Abrir la app Post Publisher
- [ ] Ir a Settings
- [ ] Confirmar que el nombre visible sigue siendo Post Publisher
- [ ] Asociar la app a la LinkedIn Page Post Publisher
- [ ] Subir el logo oficial de Post Publisher
- [ ] Configurar Website URL con https://post-publisher.ccisne.dev
- [ ] Configurar Privacy Policy URL con https://post-publisher.ccisne.dev/privacy/publisher
- [ ] Configurar Contact URL con https://post-publisher.ccisne.dev/contact si el formulario la pide
- [ ] Guardar los cambios
- [ ] Confirmar que el Client ID sigue siendo el esperado

## Paso 5. Activar productos y Auth en la app de LinkedIn

- [ ] Ir a la pestaña Products
- [ ] Activar Sign in with LinkedIn using OpenID Connect
- [ ] Activar Share on LinkedIn
- [ ] Esperar aprobacion si LinkedIn la exige para algun producto
- [ ] Ir a la pestaña Auth
- [ ] Registrar exactamente http://127.0.0.1:8787/callback como redirect URI
- [ ] Guardar los cambios de Auth
- [ ] Confirmar que LinkedIn acepta la loopback URI sin error
- [ ] Copiar Client ID
- [ ] Copiar Client Secret

## Paso 6. Configurar el CLI local

- [ ] Abrir terminal en code/cli
- [ ] Ejecutar dart run bin/main.dart auth configure
- [ ] Introducir el Client ID de la app
- [ ] Introducir el Client Secret de la app
- [ ] Introducir http://127.0.0.1:8787/callback como Redirect URI
- [ ] Introducir openid profile email w_member_social como scopes
- [ ] Introducir 202506 como API version
- [ ] Ejecutar dart run bin/main.dart auth status
- [ ] Ejecutar dart run bin/main.dart doctor
- [ ] Confirmar que ya no faltan client id, client secret y redirect uri

## Paso 7. Hacer login real con OAuth

- [ ] Ejecutar dart run bin/main.dart auth login
- [ ] Completar el consentimiento en el navegador
- [ ] Confirmar que el callback loopback vuelve al CLI sin timeout
- [ ] Si falla el callback local, ejecutar dart run bin/main.dart auth login --manual
- [ ] Ejecutar dart run bin/main.dart auth status
- [ ] Confirmar que el token quedo guardado
- [ ] Confirmar que el member profile quedo resuelto

## Paso 8. Probar la primera publicacion de texto

- [ ] Ejecutar dart run bin/main.dart post text --message "Hello, LinkedIn!"
- [ ] Confirmar que el CLI devuelve exito
- [ ] Guardar la URL del post creado
- [ ] Verificar visualmente en LinkedIn que el post existe

## Paso 9. Probar publicacion con imagen

- [ ] Ejecutar .\scripts\smoke-posts.ps1 -DryRun para revisar argumentos y archivos temporales
- [ ] Ejecutar dart run bin/main.dart post image --file <ruta_png> --message "Hello, LinkedIn!" --alt-text "Hello, LinkedIn! test image"
- [ ] Confirmar que el upload del asset termina bien
- [ ] Confirmar que LinkedIn crea el post final
- [ ] Verificar visualmente en LinkedIn que la imagen se muestra correctamente

## Paso 10. Probar publicacion con documento

- [ ] Ejecutar dart run bin/main.dart post document --file <ruta_pdf> --title "hello-linkedin.pdf" --message "Hello, LinkedIn!"
- [ ] Confirmar que el upload del documento termina bien
- [ ] Confirmar que LinkedIn crea el post final
- [ ] Verificar visualmente en LinkedIn que el documento se muestra correctamente

## Paso 11. Ejecutar el smoke test completo

- [ ] Ejecutar .\scripts\smoke-posts.ps1 -DryRun y revisar el plan completo
- [ ] Ejecutar .\scripts\smoke-posts.ps1 cuando auth y doctor ya esten verdes
- [ ] Confirmar que el script publica texto, imagen y documento en secuencia
- [ ] Anotar cualquier fallo real de LinkedIn para corregir el CLI

## Fase 2. Publicar en paginas de organizaciones propias

Esta fase amplia el CLI para publicar como organizacion (no solo como persona).
No empezar hasta que la Fase 1 (perfil personal) este validada de extremo a
extremo, porque reutiliza el mismo flujo de auth, post y media.

### Diseno tecnico de la Fase 2

- El autor de un post es un URN. Para perfil es `urn:li:person:{id}` y para
  organizacion es `urn:li:organization:{id}`. El CLI ya enruta el autor con
  prioridad flag `--organization` > `defaultOrganizationUrn` del proyecto >
  `personUrn` del perfil, asi que el cuerpo del post no cambia.
- LinkedIn solo permite publicar como organizacion si:
  - La app tiene aprobado el producto Community Management API.
  - El token incluye el scope `w_organization_social`.
  - La cuenta que autoriza tiene rol ADMINISTRATOR sobre esa Page.
- Para no pegar URNs a mano, el CLI debe poder listar las organizaciones que
  administra el usuario consultando `organizationAcls`
  (`GET /rest/organizationAcls?q=roleAssignee&role=ADMINISTRATOR&state=APPROVED`),
  lo que requiere `rw_organization_admin` o `r_organization_social`.

### Cambios de codigo requeridos para la Fase 2

- [ ] Anadir `w_organization_social` a los scopes (manteniendo los de Fase 1) y
      decidir si `r_organization_social` y `rw_organization_admin` se piden ya o
      solo cuando se implemente `org list`
- [ ] Hacer que `auth configure` y los scopes por defecto soporten el set de
      Fase 2 sin romper la Fase 1
- [ ] Ampliar `doctor` para chequear el scope de organizacion cuando el modo
      organizacion este activo
- [ ] Implementar un comando nuevo `linkedin org list` que liste las paginas que
      administra el usuario (URN y nombre) usando `organizationAcls`
- [ ] Documentar `--organization <urn>` y `defaultOrganizationUrn` en el README
- [ ] Anadir tests para `org list` y para el enrutado de autor organizacion

### Pasos operativos de la Fase 2

## Paso 12. Habilitar el producto de organizacion en LinkedIn

- [ ] Entrar en LinkedIn Developer Portal y abrir la app Post Publisher
- [ ] Ir a la pestana Products
- [ ] Solicitar Community Management API
- [ ] Completar el formulario de acceso si LinkedIn lo exige
- [ ] Esperar la aprobacion de LinkedIn para `w_organization_social`
- [ ] Confirmar que la cuenta de pruebas tiene rol ADMINISTRATOR en la Page Post Publisher

## Paso 13. Reconfigurar el CLI con scopes de organizacion

- [ ] Ejecutar dart run bin/main.dart auth configure
- [ ] Anadir w_organization_social al set de scopes (junto a los de Fase 1)
- [ ] Ejecutar dart run bin/main.dart auth login para reemitir el token con el nuevo scope
- [ ] Ejecutar dart run bin/main.dart auth status y confirmar que el scope nuevo aparece
- [ ] Ejecutar dart run bin/main.dart doctor

## Paso 14. Descubrir las organizaciones administradas

- [ ] Ejecutar dart run bin/main.dart org list
- [ ] Confirmar que aparece la organizacion con su URN urn:li:organization:{id}
- [ ] Guardar el URN de la organizacion objetivo

## Paso 15. Probar la primera publicacion como organizacion

- [ ] Ejecutar dart run bin/main.dart post text --organization urn:li:organization:{id} --message "Hello from Post Publisher (org)"
- [ ] Confirmar que el CLI devuelve exito
- [ ] Verificar visualmente que el post aparece en la Page y no en el perfil personal
- [ ] Opcional: probar post image y post document con --organization
- [ ] Opcional: fijar defaultOrganizationUrn en .post_publisher/config.json para no repetir el flag

## Pendientes tecnicos que no bloquean esta validacion

- [ ] Renombrar el slug remoto del repo en GitHub a post_publisher
- [ ] Decidir si el comando tecnico linkedin debe renombrarse en una iteracion separada
- [ ] Decidir si las variables de entorno LINKEDIN_* deben mantenerse o migrarse con compatibilidad
- [ ] Decidir si las rutas de config .post_publisher deben mantenerse estables antes de la primera release
- [ ] Documentar el dominio canonico post-publisher.ccisne.dev en el README
