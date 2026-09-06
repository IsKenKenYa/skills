# ArkTS / ArkUI codegen rules

Ordered by how often each class actually breaks the build. Scan this before writing `.ets` files, and again before calling `arkts_check`.

## Imports and exports
- All imports sit at the top of the file, before any `class`, `interface`, `struct`, `@Entry`, variable, method, or statement.
- Import only real `@kit.*` members. Never invent an export or subpath, never use a relative or synthetic Kit path (`.ArkUI`, `./ArkUI`, `ArkUI`), and never import `.ets` from `.ts`/`.js`. `@kit.ArkUI` does NOT export `ObservedV2`, `Trace`, `Resource`, `ResourceColor`, or `NavPathStack` — decorators are global and the rest are global types.
- Globals are never imported: `NavPathStack`, `AppStorage`, `Navigation`, `Scroll`, `Tabs`, `AlertDialog`, `promptAction`, `canIUse`, `getContext`, and all decorators. But `AppStorageV2` and `PersistenceV2` ARE imported from `@kit.ArkUI`.
- `router` comes from `@kit.ArkUI`; every page calling `router.*` must import it. Import `BusinessError` only from `@kit.BasicServicesKit` or `@ohos.base` — business Kits do not export it.
- Anything referenced across files needs `export`; `declares 'X' locally, but it is not exported` means the keyword is missing. Match the import form to the export form: a file with named exports needs `import { X } from './X'`, not a default import. Never import a member from the file that defines it.
- Look up per-Kit import paths, namespace members, and enum names in skill `arkts-error-fixes` (`reference/sdk_kit_symbols.md`) instead of guessing.

## State management: one generation per struct
V1 and V2 do not share an observation model; mixing them is the largest single error class.
- V1 `@Component` uses only `@State`, `@Prop`, `@Link`, `@Provide`/`@Consume`, `@Observed`+`@ObjectLink`, `@StorageLink`/`@StorageProp`, `@LocalStorageLink`/`@LocalStorageProp`, `@Watch`.
- V2 `@ComponentV2` uses only `@Local`, `@Param`, `@Once`, `@Event`, `@Provider`/`@Consumer`, `@Computed`, `@Monitor`, `@MakeObserved`.
- `@Local` inside a `@Component` (or `@State` inside a `@ComponentV2`) fails with "decorator can only be used in a 'struct' decorated with ...". Choose the generation per struct and keep it.
- A V1 state property must NOT be typed as an `@ObservedV2` class. Hold that instance in a V2 `@Local`, or model it with V1 `@Observed`+`@ObjectLink`.
- `@ObservedV2` pairs with `@Trace`; one alone observes nothing. One state decorator per property — never stack two. `@Local` and undecorated members cannot be initialized by the parent — use `@Param`.

## Page and component structure
- A `.ets` file registered in `main_pages.json` carries exactly one `@Entry` — no more, no less (`page-entry-count`). Every other screen is a plain `@Component`/`@ComponentV2`; route between them with `Navigation` + `NavDestination`, not extra `@Entry`s. Each route maps to a self-contained page file with its imports, `struct`, and `build()`.
- `build()` and `@Builder` bodies hold UI component syntax only: no local declarations, no `if`/`switch`/ternary, no state mutation, no calls to non-`@Builder` methods.
- Lifecycle hooks (`aboutToAppear`, `aboutToDisappear`) must not be `private`.
- Do not name a `CustomComponent` member `width`/`height`/`size`/`visibility`/`opacity`/`brightness`/`contrast`/`backgroundColor` — they collide with inherited attribute methods. Use a distinct name like `cardWidth`.
- Read the route stack from `NavDestinationContext.pathStack`, not `getPathStack()`. Touch handlers take `TouchEvent`/`TouchObject` (there is no `TouchInfo`). Reach UI context via `this.getUIContext()`, and app context via global `getContext(this)` — never import `getContext`.

## Strict typing
- Every object literal needs explicit type context: a typed variable, typed parameter, or declared `interface`/`class`. Never a bare `{ key: value }` (`arkts-no-untyped-obj-literals`), and never object-literal syntax as a type (`arkts-no-obj-literals-as-types`).
- Banned: `any`, `unknown`, `ESObject`, lowercase `object` as any type position, `Record<string, ...>` or index signatures as data carriers, bare `{}` fallbacks, anonymous/inline object types, TS utility types (`ReturnType`, `Partial`, `Pick`, `Omit`, `Parameters`, `Record`), type-position `typeof`, type predicates (`value is T`), non-null `!`, `require(...)`, dynamic `import(...)`, `var`, destructuring declarations/params, function/class expressions, generators, JSX, `with`, `as const`, constructor parameter fields, `delete`, `in`, `for..in`, `obj[key]` (`arkts-no-props-by-index`), `Reflect.get`, `hasOwnProperty`, `.call`/`.apply`, `Object.entries`, and `.values()` on an enum.
- Declare named `class`/`interface` models with explicit fields, params, returns, and generics. Use `===`, `!==`, `?.`, `??`; normalize optional numbers before math.
- `catch` takes no type annotation: write `catch (error)` then `const err = error as BusinessError;`. A Promise `.catch` callback that uses the error must type it: `.catch((error: BusinessError) => { ... })`.
- Hoist helpers to file scope or named static methods — no nested/local function declarations. Static and exported helpers never use `this` (`arkts-no-standalone-this`).
- Treat `JSON.parse`, Preferences, router params, AppStorage, and SDK callbacks as opaque until normalized by `typeof`/null checks. Cast parsed JSON once to a named raw model (`JSON.parse(raw) as TaskRawInput`), then validate and copy fields into strict models. Never probe with `'field' in data`, `obj[key]`, or `Object.keys(...)+index`; for dynamic arrays hold elements as `Object`, check `typeof`, then push into a typed array. Never pass a string literal where an enum is expected.

## Component attributes and enums
- Every chained attribute must exist on that component's `XAttribute` type — do not invent one, and do not borrow a neighbour's. Frequent misses: `Stack` uses `.alignContent(Alignment)` while `.justifyContent()` belongs to `Row`/`Column`/`Flex`; minimum size is `.constraintSize({ minWidth })`, not `.minWidth()`/`.minHeight()`; `.hideNavBar()` is on `Navigation`, not `NavDestination`, and `Navigation` has no `.onReady()` — supply destinations with `.navDestination(builder)`; `List` uses `.alignListItem(ListItemAlign)` (not `ListItemAlignment`) and has no `alignItems`/`listItemGap`; style `Tabs` bars with `BottomTabBarStyle`/`SubTabBarStyle` via `TabContent.tabBar()`, not `.barActiveColor()`/`.selectedColor()`; `Slider` uses `.gesture()` not `.onGesture()`; `TimePicker` uses `.textStyle(PickerTextStyle)` not `.fontSize()`; security components such as `SaveButton` accept `.padding()` but not `.margin()`.
- Some options are constructor parameters, not chained methods: `Row({ space })`, `Column({ space })`, `ListItemGroup({ header })`, `Refresh({ refreshing })`, `Progress({ total, value })` — observe their state via `.onRefreshing()`/`.onStateChange()`.
- Enum member names and casing must match the SDK exactly (`ButtonType.CAPSULE`, `TouchType.Up`, `LineCapStyle.Round`, `BlurStyle.Thin`, `GradientDirection.RightBottom`, `DialogAlignment.Center`). `Color` offers only White/Black/Blue/Brown/Gray/Green/Grey/Orange/Pink/Red/Yellow/Transparent — no `Gold`; use a hex string or `Resource`. `Curve` has no `Spring`; take a spring curve from `@ohos.curves` via `curves.springCurve(...)`. `AppStorage` exposes `setOrCreate`/`get`/`set`/`has`, and `AlertDialog` is called as `AlertDialog.show(...)`. Verify a member exists before using it; when a name looks plausible but you have not seen it in the SDK, check skill `arkts-error-fixes` (`reference/sdk_kit_symbols.md`).
- Match an existing overload: check argument count and types before calling, and do not pass generic type arguments to methods that take none.
