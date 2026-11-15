import { Controller } from "@hotwired/stimulus"
import { DefaultService } from "../generated"
import type { EventType } from "../generated"

export default class extends Controller {
  static targets = ["status", "list", "retry", "create"]
  declare readonly statusTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly retryTarget: HTMLButtonElement
  declare readonly createTarget: HTMLAnchorElement

  connect() {
    this.load()
  }

  async load() {
    this.statusTarget.textContent = "Загрузка типов событий…"
    this.retryTarget.classList.add("d-none")
    this.createTarget.classList.add("d-none")
    this.listTarget.replaceChildren()
    try {
      const { data } = await DefaultService.listEventTypes()
      this.statusTarget.textContent = data.length ? "" : "Пока нет доступных типов событий"
      this.createTarget.classList.toggle("d-none", data.length !== 0)
      data.forEach((eventType) => this.renderEventType(eventType))
    } catch {
      this.statusTarget.textContent = "Не удалось загрузить типы событий. Попробуйте ещё раз."
      this.retryTarget.classList.remove("d-none")
    }
  }

  renderEventType(eventType: EventType) {
    const column = document.createElement("div")
    column.className = "col-md-6"
    const card = document.createElement("article")
    card.className = "card h-100 border-0 shadow-sm rounded-4"
    const body = document.createElement("div")
    body.className = "card-body p-4"
    const title = document.createElement("h3")
    title.className = "h5 fw-bold"
    title.textContent = eventType.name
    const description = document.createElement("p")
    description.className = "text-secondary"
    description.textContent = eventType.description
    const duration = document.createElement("span")
    duration.className = "badge text-bg-light"
    duration.textContent = `${eventType.duration_minutes} минут`
    body.append(title, description, duration)
    card.append(body)
    column.append(card)
    this.listTarget.append(column)
  }
}
