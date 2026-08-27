# Patch notes en curso

Lo que va acumulado desde el último update, listo para publicar como patch.
Formato de Discord abajo, se copia tal cual.

---

# :wrench: Patch 28.0.2 - DOJO STUDENTS

## :mortar_board: DOJO
- **Fixed students never ranking up when their promotion bar was full.** If the card says "Ready for Special Grade", the next training session promotes them. No more sitting at 253/189 forever
- Students now also rank up from the dojo activities that were only feeding their progress bar and nothing else: rival dojo challenges, dojo events, and assistant training sessions
- Every promotion is announced in the log, whichever activity caused it
- Renamed the buttons on the student card. **TRAIN** now runs the training session, and the new **FOCUS** button opens the page where you pick the training focus. The button that actually trained used to be labelled MISSION

---

## Notas internas, no van a Discord

- Causa raíz: `STUDENT_GRADE_ORDER`, la fórmula de poder, el potential score y la regla de
  promoción estaban copiados en `BK_DojoService`, `BK_ActivityService` y `BK_AssetService`.
  La copia de `BK_DojoService` solo alimentaba la tarjeta ("Ready for <grade>"); las copias
  que promovían de verdad vivían en los otros dos y tiraban un dado (78% como mucho). Encima,
  tres sitios sumaban `DojoProgress` y no comprobaban la promoción **nunca**: el reto al dojo
  rival, los eventos de dojo y `assistant_train_npcs`. Por eso la barra se llenaba y se quedaba
  llena.
- Fix: `ReplicatedStorage.BitKaisenDojoStudents` es ahora la única fuente de verdad
  (grados, poder, potential, `GetPromotionInfo`, `TryPromote`, `PromoteReadyStudents`).
  Los tres servicios delegan en él. Se borraron 215 líneas duplicadas y se añadieron 58.
- **Cambio de balance, revisable:** `TryPromote` es **determinista**. Antes era una tirada
  (20 + potential*8 + power/20, cap 80%). El ritmo lo siguen marcando `needed` (45 + índice*18,
  que sube por grado), el reseteo de progreso al 25% al ascender y las ventanas de 6 meses de
  `TrainStudents` y del patrol. Si lacocaim quiere volver al dado, es una sola función.
- No se tocó `GameManager`. Los tres servicios están muy por debajo del techo de locals
  (93, 128 y 42 de ~200).
- Verificado: `selene` sin regresiones en los 5 archivos (0 errores, 0 parse errors; los
  avisos son idénticos al baseline). `rojo build` NO se pudo correr aquí porque `blink`
  necesita una terminal real para generar `remotes/out/`: hay que correr `just check` en una
  consola de verdad.
- Tests unitarios: `just test` corre `tests/dojo_students.test.luau` con zune, fuera de
  Studio. 53 checks sobre la escalera de grados, la fórmula de poder, el estudiante exacto
  del reporte (253/189), determinismo, la puerta de CE del Non-Sorcerer y los filtros del
  barrido. Ya cazó un crash: el idioma `and/or` en `PromoteReadyStudents` llamaba a
  `roleFilter` (nil) con cualquier relación que no fuera Student o Ward.
- **Falta probar en vivo**: subir un estudiante con la barra llena por cada una de las cinco
  rutas (TrainStudents, patrol, grade review, pair sparring, reto al dojo rival) y confirmar
  que el mensaje de ascenso sale en el log.

---


# :wrench: Patch 28.0.1 - LANGUAGE FIX

## :globe_with_meridians: LANGUAGE
- Fixed the shared world log, the final-seal popups and the era-change popup showing up in Spanish for everyone
- Fixed the "the world moved on" message you get when joining an older public world showing up in Spanish
- Fixed your legend grade being shown in Spanish after a world got sealed. Already-sealed lives keep their grade and now read it in your own language
- Fixed cell, duel and Lives-tab popups tagging themselves in Spanish
- Fixed the Era Oath and the rematch tag showing up in Spanish on the Lives tab and in the duel screen
- Fixed the era arrow rendering as broken characters in the age-up log
- Spanish and Portuguese players now get translations for durability, speed and CE efficiency training, cursed tool requests, promotion recommendations and subordinate missions, which were English-only

## :wrench: Everything else
- Fixed recommending a subordinate for promotion reporting a different reputation number than the one you actually gained

---

## Notas internas, no van a Discord

- El juego se escribe en inglés en el código; español y portugués viven solo en
  `game/shared/locale/es.luau` y `pt_br.luau`. Esta tanda saca de `GameManager`,
  `BK_CellService`, `BK_DuelService`, `BK_SoulsService` y cinco paneles de UI todo
  el texto que estaba escrito en español y lo pasa por `tOrFallback`.
- Los eventos del log compartido del mundo (`BK_WorldStateService.AddEvent`) quedan
  en inglés fijo: es un solo log persistido para todos los jugadores del mundo, no
  se puede traducir por jugador sin rehacer cómo se guarda.
- `PublicLegendGrade` ahora se guarda en inglés. Los paneles de World History
  reconocen también los valores viejos en español, así que no hace falta migrar
  ningún save.
- `BitKaisenLocale.tOrFallbackAny` es nuevo: acepta que una clave sea una lista de
  frases y elige una al azar, para no aplastar la variedad de los textos de
  entrenamiento. `tAct` ya la usa para las 99 claves de actividad.
- `check_translations.ps1` ahora, además de la cobertura de claves, barre los 202
  `.luau` fuera de `locale/` buscando español o portugués hardcodeado. Correrlo
  antes de cerrar cada update.
- Sin tocar: `canUseDevTools` sigue dejando el panel de DevTools abierto a cualquier
  jugador en la place publicada.

---

---

# :wrench: Patch 27.0.1 - MULTIPLAYER FIXED

## :globe_with_meridians: MULTIPLAYER IS FIXED
- **YOU CAN CREATE AND JOIN WORLDS AGAIN**
- Fixed joining a world dropping you into a blank screen with no character loaded
- Fixed worlds always showing 0 players in the browser even when people were inside
- Fixed Join and Create doing nothing when tapped on mobile
- Fixed the world list going blank when reopening the browser too quickly
- Fixed a world you just created not showing up in the list until 15 seconds later
- Teleport failures now tell you the real reason and retry, instead of leaving you stuck on "Teleporting..." forever

## :wrench: Everything else
- Fixed requesting a cursed tool from the institution not actually giving you one, even when the request was approved
- Fixed the system log cutting off mid sentence on long lives
- Fixed world events showing up in Spanish for everyone (Golden Peace, Crackdown)
- Fixed CE Potential, CE Output, CE Reinforcement and CE Control not being visible on mobile
- Fixed the in-game update log being stuck on Update 23

---

## Notas internas, no van a Discord

- Bug de crear/unirse a mundos: DOS causas encontradas, ninguna testeada todavía.
  Se descartó primero la capa de datos (24 mundos sanos, 0 sellados, 8 visibles).

  1. `Players.PlayerAdded` en GameManager no tenía loop de catch-up para jugadores
     ya presentes. En un servidor reservado recién creado el que se teleporta ES el
     primer jugador y llega mientras arranca el script de 13k líneas, así que su
     evento nunca disparaba: sin vida, sin prompt, pantalla muerta. Además
     `currentWorldId` nunca se seteaba desde el TeleportData, por eso el heartbeat
     reportaba población a genesis y los mundos reales salían siempre en 0.
     Esta explica la evidencia completa. Es la causa principal.

  2. Se usaba `TeleportToPrivateServer`, API deprecada que ENCOLA el teleport y
     retorna de inmediato, por eso el pcall reportaba éxito aunque fallara después.
     Migrado a `TeleportAsync` + `TeleportOptions`, que lanza error real, con
     3 reintentos y espera creciente por el rate limit de Roblox.

  Si aun así falla, RUN DIAGNOSTIC en DevTools y el handler de TeleportInitFailed
  dan el error exacto.
- "Text doesn't finish writing" se arregló con un cap de caracteres. Confiable pero
  sin reproducir el corte original, vale que un tester confirme.
- Pendiente sin tocar: "Family Type Change" (civil pasa a hechicero al subir de grado,
  parece intencional en `syncFamilyStatus`).
- Aparte: `canUseDevTools` deja el panel de DevTools abierto a cualquier jugador en la
  place publicada. No es un bug de esta tanda pero sigue ahí.
