# Update 28 — Bloodline

Tema: la sangre con la que naces decide la vida que juegas.

Elegido porque responde a la queja más repetida de los jugadores ("there's
basically no life simulation involved anymore"), no requiere tocar UI, no toca
saves ni remotes, y se apoya en motores que ya existían y estaban vacíos.

---

## Para akira (thumbnail)

> Update 28 trata del linaje. Los 37 clanes y linajes ahora tienen su propia
> vida: infancia, adolescencia, adultez y vejez distintas, más decisiones
> exclusivas en misiones que solo tu clan puede tomar. Nacer Gojo ya no se
> juega igual que nacer civil.

Ángulo visual: clanes. Es lo único dibujable de un update de contenido y es
instantáneamente reconocible para fans de JJK. Split con personajes de clanes
distintos, texto tipo "YOUR BLOODLINE DECIDES".

El tema ya no va a cambiar, así que el thumbnail se puede hacer desde ya.

---

## Estado final

| | Antes | Ahora |
|---|---|---|
| Eventos de vida | 39 | **137** |
| Eventos con clan | 4 | **57** |
| Eventos con técnica | 0 | **35** |
| Eventos que empiezan a los 40+ | **0** | **20** |
| Situaciones | 10 | **25** |
| Opciones de situación | ~60 | **167** |
| Opciones con clan | 0 | **35** |
| Líneas de nacimiento propias | 4 | **37** |
| Líneas de muerte propias | 0 | **37** |
| Eventos traducidos (es / pt_br) | 39 / 39 | **137 / 137** |
| Situaciones traducidas (es / pt_br) | **0 / 0** | **25 / 25** |
| Líneas de nacimiento traducidas | **0 / 0** | **37 / 37** |
| Líneas de muerte traducidas | **0 / 0** | **37 / 37** |

## Cambios de sistema (no solo contenido)

- `BitKaisenSituations`: soporte de `RequiresOrigin` y `RequiresOriginCategory`
  en las opciones. No existía. Es lo que permite que el clan cambie **lo que
  puedes hacer**, no solo lo que se narra.
- `BitKaisenLifeEvents`: `RollEvent` propaga `SourceOrigin` y `SourceTechnique`,
  y `ApplyEvent` los muestra como etiqueta de color en el log (`[ GOJO CLAN ]`
  dorado, `[ LIMITLESS ]` morado). Sin esto el jugador nunca se entera de que
  los eventos le salen por su sangre, y 137 eventos se sienten igual de
  aleatorios que 39.
- `getBirthOriginMessage`: `ORIGIN_BIRTH_LINES`, una línea escrita por origen.
  Era lo primero que se lee en **cada** vida y decía lo mismo para 33 de 37.
- Muerte por vejez: `ORIGIN_DEATH_LINES`, un cierre por origen. Antes devolvía
  "Your life reached its final year." para los 37 por igual.
- **Localización de situaciones, que nunca existió.** `BK_MissionService` ni
  siquiera requería el módulo de locale. Ahora:
  - `BitKaisenLocale.getSituationLocale(locale, id)` nuevo.
  - `GetOptionsForPlayer` devuelve copias superficiales con `SourceIndex`,
    porque las opciones se filtran por clan y técnica y la posición en la lista
    filtrada no corresponde a la posición original. Sin ese índice, la
    traducción se aplicaría a la opción equivocada.
  - `BK_MissionService` traduce título, cuerpo, y el `Text` y `Description` de
    cada opción. Las opciones traducidas son las que se guardan en
    `pendingMissions`, así que la descripción que sale después de elegir
    también queda traducida, no solo el botón.

## Verificación hecha

- `selene` limpio, **0 parse errors** en los nueve archivos tocados. Los 5
  errores que reporta GameManager son preexistentes y ya estaban en HEAD.
- GameManager sigue en **200/200 locals**. Todo lo nuevo usa globales o vive
  dentro de funciones. Ojo: el archivo está EN el techo, cualquier `local` de
  nivel superior nuevo lo rompe con "Out of local registers".
- Todos los `RequiredOrigin`, `RequiredTechnique`, `RequiresOrigin` y
  `RequiresSpecificTechnique` cruzados contra los strings reales de
  `BitKaisenStats`. Cero desajustes.
- `ORIGIN_BIRTH_LINES` y `ORIGIN_DEATH_LINES` con cobertura 37/37.
- Traducciones: 137/137 eventos y 25/25 situaciones en ambos idiomas, con el
  **mismo número de variantes y de opciones** que el original. Si faltara una,
  esa variante caería a inglés en silencio.
- Simulación del filtro: **las 25 situaciones tienen 3+ opciones sin gate**, o
  sea siguen jugables para un civil sin técnica. Ese era el riesgo real,
  `RollSituation` descarta cualquier situación con menos de 2 disponibles.
- Prueba funcional previa en Studio (`loadstring` sobre el Source, porque
  `require` cachea): 5 perfiles reciben pools distintos (23/22/21/19/16).

### Falta verificar en vivo

Studio estuvo cerrado durante la segunda mitad del trabajo. Lo intenté seis
veces. Falta correr el test de perfiles otra vez contra el juego real para
confirmar situaciones nuevas, vejez, líneas de muerte y las traducciones. Son
dos minutos cuando lo abras.

---

## Release

El update log **ya está puesto** en `UpdateLogPanel.luau` y
`MobileUpdateLogPanel.luau`, título en UPDATE 28 y tres secciones nuevas.

### Texto de Discord, listo para pegar

```
# :drop_of_blood: UPDATE 28: BitKaisen :scroll:

## :dna: YOUR BLOODLINE DECIDES
- **ALL 37 CLANS AND LINEAGES NOW HAVE THEIR OWN LIFE STORY**
- Being born a Gojo means elders measuring you and no children allowed near you. A Zenin is ranked by strength in front of the family. A Death Painting understands it was made, not born
- Childhood, adolescence, adulthood and old age all read differently depending on the name you were born into
- Every origin now has its own written birth line and its own ending, instead of one generic sentence for everyone
- Bloodline events are labelled in the system log, so you can finally see when your blood is what made something happen

## :hourglass: The second half of life
- Life after 40 now has content of its own: a body that stops answering while your technique stays sharp, outliving the people you trained beside, being asked to teach instead of deploy, and the reckoning that comes with it
- Clan-specific late life too. The Gojo with nobody left to correct them, the Zenin who is now the one ranking the next generation, the Kenjaku who starts thinking about the next body instead of the next year

## :crossed_swords: Choices only your clan can take
- Mission situations now offer options locked to your bloodline. A Zenin triages the way they were raised to, a Nanami separates the work from the grief, a Todo asks a rival what kind of person they like mid-fight
- More situations overall, and more technique-specific ways to solve them

## :globe_with_meridians: Fully translated
- Everything new is in Spanish and Portuguese from day one, including mission situations, which were English-only until now

https://www.roblox.com/games/75568616291684/BitKaisen

@everyone
```

---

## Aviso de publicación

El patch 27.0.1 **ya salió**, con los arreglos de multiplayer y el resto de
bugs. Por eso el post del Update 28 no los repite: solo lleva contenido nuevo.

Nombre del juego para este update: **[:drop_of_blood: BLOODLINE] BitKaisen**,
para que el nombre, el thumbnail y el post digan lo mismo.

## Fuera de alcance, movido a updates siguientes

- Shikigami pt1+pt2 (posturas Asalto/Guardia/Sostén ya diseñadas)
- Mapa de Tokio con distritos, viaje y wanted, con arquitectura de nodos que no
  se case con Tokio para poder agregar Kyoto y las colonias después
- Gamepass (candidato: Shikigami Master, el único que no pisa Premium Origins
  ni Legacy Blessing)
- Combate con selección de movimientos (pedido de Rei en el Discord)

## Deuda restante

Ninguna del contenido nuevo: eventos, situaciones, y líneas de nacimiento y
muerte están al 100% en español y portugués.

Queda pendiente, de antes de este update, que `BitKaisenScenarios` y el resto
del texto viejo siguen con su cobertura original.
