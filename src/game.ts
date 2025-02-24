// --- ECS Types ---

type Entity = number;

// Component Types
interface Position {
  x: number;
  y: number;
}

interface Velocity {
  x: number;
  y: number;
}

interface Sprite {
  image: string;
}

interface Health {
  hp: number;
}

interface Weapon {
  damage: number;
  type: string;
}

interface Augmentation {
  type: 'cloaking' | 'jet_boost';
  active: boolean;
}

interface Input {
  right: boolean;
  left: boolean;
  jump: boolean;
  augment: boolean;
  attack: boolean;
}

interface EnergyCore {
  amount: number;
  max: number;
}

interface Collision {
  width: number;
  height: number;
}

// Component Storage
interface Components {
  Position: Record<Entity, Position>;
  Velocity: Record<Entity, Velocity>;
  Sprite: Record<Entity, Sprite>;
  Health: Record<Entity, Health>;
  Weapon: Record<Entity, Weapon>;
  Augmentation: Record<Entity, Augmentation>;
  Input: Record<Entity, Input>;
  EnergyCore: Record<Entity, EnergyCore>;
  Collision: Record<Entity, Collision>;
}

// --- ECS Setup ---

const entities: Record<Entity, boolean> = {};
let nextEntityId: Entity = 0;

const components: Components = {
  Position: {},
  Velocity: {},
  Sprite: {},
  Health: {},
  Weapon: {},
  Augmentation: {},
  Input: {},
  EnergyCore: {},
  Collision: {},
};

// Add a component to an entity
function addComponent<T extends keyof Components>(
  entity: Entity,
  componentType: T,
  data: Components[T][Entity],
): void {
  components[componentType][entity] = data;
}

// Create an entity with components
function createEntity(componentsList: [keyof Components, any][]): Entity {
  const entity: Entity = nextEntityId++;
  entities[entity] = true;
  componentsList.forEach(([type, data]) => addComponent(entity, type, data));
  return entity;
}

// --- Entity Creation ---

// Player 1 (Cyber-Shogunate Stealth)
const player1: Entity = createEntity([
  ['Position', { x: 0, y: 0 }],
  ['Velocity', { x: 0, y: 0 }],
  ['Sprite', { image: 'neon_samurai' }],
  ['Health', { hp: 100 }],
  ['Weapon', { damage: 20, type: 'plasma_katana' }],
  ['Augmentation', { type: 'cloaking', active: false }],
  [
    'Input',
    { right: false, left: false, jump: false, augment: false, attack: false },
  ],
  ['EnergyCore', { amount: 50, max: 100 }],
]);

// Player 2 (Neon East India Brute)
const player2: Entity = createEntity([
  ['Position', { x: 50, y: 0 }],
  ['Velocity', { x: 0, y: 0 }],
  ['Sprite', { image: 'cyber_brute' }],
  ['Health', { hp: 120 }],
  ['Weapon', { damage: 30, type: 'mech_mace' }],
  ['Augmentation', { type: 'jet_boost', active: false }],
  [
    'Input',
    { right: false, left: false, jump: false, augment: false, attack: false },
  ],
  ['EnergyCore', { amount: 50, max: 100 }],
]);

// Enemy (Cyborg Knight)
const enemy: Entity = createEntity([
  ['Position', { x: 100, y: 0 }],
  ['Velocity', { x: 0, y: 0 }],
  ['Sprite', { image: 'cyborg_knight' }],
  ['Health', { hp: 80 }],
  ['Collision', { width: 20, height: 20 }],
]);

// Platform
const platform: Entity = createEntity([
  ['Position', { x: 0, y: -10 }],
  ['Collision', { width: 200, height: 10 }],
]);

// --- Systems ---

// Input System
function inputSystem(): void {
  for (const entity in components.Input) {
    const e: Entity = Number(entity);
    const input: Input = components.Input[e];
    const vel: Velocity = components.Velocity[e];
    const aug: Augmentation = components.Augmentation[e];
    const core: EnergyCore = components.EnergyCore[e];

    // Movement
    vel.x = input.right ? 5 : input.left ? -5 : 0;
    if (input.jump && vel.y === 0) vel.y = 10; // Jump only if grounded

    // Augmentation (costs energy)
    if (input.augment && core.amount >= 20) {
      aug.active = true;
      core.amount -= 20;
      if (aug.type === 'jet_boost') vel.y = 15; // Boost higher
    } else {
      aug.active = false;
    }
  }
}

// Movement System
function movementSystem(dt: number): void {
  for (const entity in components.Position) {
    const e: Entity = Number(entity);
    const pos: Position = components.Position[e];
    const vel: Velocity | undefined = components.Velocity[e];
    if (!vel) continue;

    // Update position
    pos.x += vel.x * dt;
    pos.y += vel.y * dt;

    // Gravity
    vel.y -= 20 * dt; // 20 = gravity strength

    // Ground check (y = 0 floor)
    if (pos.y < 0) {
      pos.y = 0;
      vel.y = 0;
    }
  }
}

// Collision System
function collisionSystem(): void {
  for (const entityA in components.Collision) {
    const eA: Entity = Number(entityA);
    const posA: Position = components.Position[eA];
    const colA: Collision = components.Collision[eA];
    for (const entityB in components.Position) {
      const eB: Entity = Number(entityB);
      if (eA === eB || !components.Collision[eB]) continue;
      const posB: Position = components.Position[eB];
      const colB: Collision = components.Collision[eB];

      // AABB collision
      if (
        posA.x < posB.x + colB.width &&
        posA.x + colA.width > posB.x &&
        posA.y < posB.y + colB.height &&
        posA.y + colA.height > posB.y
      ) {
        const velA: Velocity | undefined = components.Velocity[eA];
        if (velA) {
          velA.x = 0;
          velA.y = 0;
          posA.y = posB.y + colB.height; // Land on platform
        }
      }
    }
  }
}

// Combat System
function combatSystem(): void {
  for (const entity in components.Input) {
    const e: Entity = Number(entity);
    const input: Input = components.Input[e];
    if (!input.attack) continue;

    const pos: Position = components.Position[e];
    const weapon: Weapon = components.Weapon[e];
    for (const target in components.Health) {
      const t: Entity = Number(target);
      if (t === e) continue;
      const targetPos: Position = components.Position[t];

      // Range check
      if (
        Math.abs(pos.x - targetPos.x) < 30 &&
        Math.abs(pos.y - targetPos.y) < 10
      ) {
        components.Health[t].hp -= weapon.damage;
        console.log(`Entity ${t} hit! HP: ${components.Health[t].hp}`);
      }
    }
  }
}

// Augmentation System (Co-op Energy Core Sharing)
function augmentationSystem(): void {
  const players: Entity[] = Object.keys(components.EnergyCore).map(Number);
  const p1Core: EnergyCore = components.EnergyCore[players[0]];
  const p2Core: EnergyCore = components.EnergyCore[players[1]];

  // Simulate core trading (toggle every 2 seconds)
  if (Math.floor(Date.now() / 2000) % 2 === 0) {
    p1Core.amount = 80;
    p2Core.amount = 20;
  } else {
    p1Core.amount = 20;
    p2Core.amount = 80;
  }
}

// Rendering System (Console-based)
function renderingSystem(): void {
  console.clear();
  for (const entity in components.Sprite) {
    const e: Entity = Number(entity);
    const pos: Position = components.Position[e];
    const sprite: Sprite = components.Sprite[e];
    const health: Health | undefined = components.Health[e];
    console.log(
      `${sprite.image} at (${Math.round(pos.x)}, ${Math.round(pos.y)})${
        health ? ` HP: ${health.hp}` : ''
      }`,
    );
  }
}

// --- Game Loop ---

let lastTime: number = Date.now();
export function gameLoop(): void {
  const now: number = Date.now();
  const dt: number = (now - lastTime) / 1000; // Delta time in seconds
  lastTime = now;

  // Simulate input (for demo)
  components.Input[player1].right = Math.random() > 0.5;
  components.Input[player1].jump = Math.random() > 0.8;
  components.Input[player1].augment = Math.random() > 0.9;
  components.Input[player1].attack = Math.random() > 0.85;
  components.Input[player2].left = Math.random() > 0.5;
  components.Input[player2].augment = Math.random() > 0.9;

  // Run systems
  inputSystem();
  movementSystem(dt);
  collisionSystem();
  combatSystem();
  augmentationSystem();
  renderingSystem();

  requestAnimationFrame(gameLoop);
}

// Start the game
// gameLoop();
