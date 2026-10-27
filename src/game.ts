// ECS System
class Entity {
  id: number;
  components: Map<string, any>;

  constructor(id: number) {
    this.id = id;
    this.components = new Map();
  }

  addComponent(type: string, component: any) {
    this.components.set(type, component);
  }

  getComponent(type: string) {
    return this.components.get(type);
  }
}

class ECS {
  entities: Entity[] = [];
  currentId: number = 0;

  createEntity() {
    const entity = new Entity(this.currentId++);
    this.entities.push(entity);
    return entity;
  }
}

// Components
interface PositionComponent {
  x: number;
  y: number;
}

interface VelocityComponent {
  dx: number;
  dy: number;
}

interface SpriteComponent {
  image: HTMLImageElement;
  width: number;
  height: number;
}

interface InputComponent {
  keys: { [key: string]: boolean };
}

// Systems
class MovementSystem {
  update(entities: Entity[]) {
    entities.forEach((entity) => {
      const position = entity.getComponent('position') as PositionComponent;
      const velocity = entity.getComponent('velocity') as VelocityComponent;
      if (position && velocity) {
        position.x += velocity.dx;
        position.y += velocity.dy;
      }
    });
  }
}

class RenderSystem {
  ctx: CanvasRenderingContext2D;
  background: HTMLImageElement;

  constructor(ctx: CanvasRenderingContext2D) {
    this.ctx = ctx;
    this.background = new Image();
    this.background.src = 'Background_1.png'; // Background sprite
  }

  update(entities: Entity[]) {
    // Draw background
    this.ctx.clearRect(0, 0, this.ctx.canvas.width, this.ctx.canvas.height);
    this.ctx.drawImage(
      this.background,
      0,
      0,
      this.ctx.canvas.width,
      this.ctx.canvas.height,
    );

    entities.forEach((entity) => {
      const position = entity.getComponent('position') as PositionComponent;
      const sprite = entity.getComponent('sprite') as SpriteComponent;
      if (position && sprite) {
        this.ctx.drawImage(
          sprite.image,
          position.x,
          position.y,
          sprite.width,
          sprite.height,
        );
      }
    });
  }
}

class InputSystem {
  update(entities: Entity[]) {
    entities.forEach((entity) => {
      const input = entity.getComponent('input') as InputComponent;
      if (input) {
        const velocity = entity.getComponent('velocity') as VelocityComponent;
        if (velocity) {
          velocity.dx = 0;
          velocity.dy = 0;
          if (input.keys['ArrowLeft']) velocity.dx = -2;
          if (input.keys['ArrowRight']) velocity.dx = 2;
          if (input.keys['ArrowUp']) velocity.dy = -2;
          if (input.keys['ArrowDown']) velocity.dy = 2;
        }
      }
    });
  }
}

class AttackSystem {
  update(entities: Entity[]) {
    entities.forEach((entity) => {
      const input = entity.getComponent('input') as InputComponent;
      if (input && input.keys[' ']) {
        // Space key for attack
        console.log(`${entity.id} is attacking!`);
        // Add attack animation logic here using _AttackNoMovement.png
      }
    });
  }
}

// Game Setup
const canvas = document.getElementById('gameCanvas') as HTMLCanvasElement;
canvas.width = 800;
canvas.height = 600;
const ctx = canvas.getContext('2d')!;

const ecs = new ECS();
const movementSystem = new MovementSystem();
const renderSystem = new RenderSystem(ctx);
const inputSystem = new InputSystem();
const attackSystem = new AttackSystem();

// Create Player Entity
const player = ecs.createEntity();
player.addComponent('position', { x: 100, y: 100 } as PositionComponent);
player.addComponent('velocity', { dx: 0, dy: 0 } as VelocityComponent);
const playerSprite = new Image();
playerSprite.src = '_AttackNoMovement.png'; // Attack sprite
player.addComponent('sprite', {
  image: playerSprite,
  width: 32,
  height: 32,
} as SpriteComponent);
player.addComponent('input', { keys: {} } as InputComponent);

// Handle Input
document.addEventListener('keydown', (e) => {
  const input = player.getComponent('input') as InputComponent;
  if (input) input.keys[e.key] = true;
});

document.addEventListener('keyup', (e) => {
  const input = player.getComponent('input') as InputComponent;
  if (input) input.keys[e.key] = false;
});

// Game Loop
function gameLoop() {
  inputSystem.update(ecs.entities);
  movementSystem.update(ecs.entities);
  attackSystem.update(ecs.entities);
  renderSystem.update(ecs.entities);
  requestAnimationFrame(gameLoop);
}

gameLoop();
