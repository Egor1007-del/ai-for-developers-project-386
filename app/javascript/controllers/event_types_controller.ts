import { Controller } from "@hotwired/stimulus"
import { ApiError, DefaultService, OpenAPI } from "../generated"
import type { Day, EventType, Slot } from "../generated"

export default class extends Controller {
  static targets = ["status", "list", "retry", "create", "booking", "heading", "bookingStatus", "bookingRetry", "days", "slots", "selection", "confirm", "controls"]
  declare readonly controlsTarget: HTMLFieldSetElement
  declare readonly statusTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly retryTarget: HTMLButtonElement
  declare readonly createTarget: HTMLAnchorElement
  declare readonly bookingTarget: HTMLElement
  declare readonly headingTarget: HTMLElement
  declare readonly bookingStatusTarget: HTMLElement
  declare readonly bookingRetryTarget: HTMLButtonElement
  declare readonly daysTarget: HTMLElement
  declare readonly slotsTarget: HTMLElement
  declare readonly selectionTarget: HTMLElement
  declare readonly confirmTarget: HTMLButtonElement
  private selectedType?: EventType
  private selectedSlot?: Slot
  private requestVersion = 0
  private submitting = false

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
    const choose = document.createElement("button")
    choose.type = "button"
    choose.className = "btn btn-outline-primary d-block mt-3"
    choose.textContent = `Выбрать ${eventType.name}`
    choose.addEventListener("click", () => {
      this.selectedType = eventType
      this.headingTarget.textContent = `Выберите дату и время: ${eventType.name}`
      this.bookingTarget.classList.remove("d-none")
      this.loadAvailability()
    })
    body.append(title, description, duration, choose)
    card.append(body)
    column.append(card)
    this.listTarget.append(column)
  }

  async loadAvailability(message = "") {
    if (!this.selectedType) return
    const version = ++this.requestVersion
    this.selectedSlot = undefined
    this.confirmTarget.classList.add("d-none")
    this.selectionTarget.textContent = ""
    this.daysTarget.replaceChildren()
    this.slotsTarget.replaceChildren()
    this.bookingRetryTarget.classList.add("d-none")
    this.bookingStatusTarget.textContent = "Загрузка доступности…"
    try {
      const availability = await DefaultService.getAvailability(this.selectedType.id)
      if (version !== this.requestVersion) return
      this.bookingStatusTarget.textContent = message || "Выберите дату (московское время)"
      availability.days.forEach((day) => this.renderDay(day))
    } catch {
      if (version !== this.requestVersion) return
      this.bookingStatusTarget.textContent = message ? `${message} Не удалось обновить доступность.` : "Не удалось загрузить доступность. Попробуйте ещё раз."
      this.bookingRetryTarget.classList.remove("d-none")
    }
  }

  retryAvailability() {
    this.loadAvailability()
  }

  renderDay(day: Day) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "btn btn-outline-secondary"
    button.textContent = day.date
    button.disabled = day.slots.length === 0
    button.addEventListener("click", () => {
      this.selectedSlot = undefined
      this.selectionTarget.textContent = ""
      this.confirmTarget.classList.add("d-none")
      this.slotsTarget.replaceChildren()
      day.slots.forEach((slot) => {
        const time = document.createElement("button")
        time.type = "button"
        time.className = "btn btn-outline-primary"
        time.textContent = new Intl.DateTimeFormat("ru-RU", { timeZone: "Europe/Moscow", hour: "2-digit", minute: "2-digit" }).format(new Date(slot.starts_at))
        time.addEventListener("click", () => {
          this.selectedSlot = slot
          this.selectionTarget.textContent = `Выбрано: ${day.date}, ${time.textContent} (Москва)`
          this.confirmTarget.classList.remove("d-none")
        })
        this.slotsTarget.append(time)
      })
    })
    this.daysTarget.append(button)
  }

  async confirm() {
    if (!this.selectedType || !this.selectedSlot || this.submitting) return
    const type = this.selectedType
    const slot = this.selectedSlot
    this.submitting = true
    this.controlsTarget.disabled = true
    this.bookingStatusTarget.textContent = "Создание записи…"
    OpenAPI.HEADERS = { "X-CSRF-Token": document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "" }
    try {
      const booking = await DefaultService.createBooking({ event_type_id: type.id, starts_at: slot.starts_at })
      const formatted = new Intl.DateTimeFormat("ru-RU", { timeZone: "Europe/Moscow", dateStyle: "short", timeStyle: "short" }).format(new Date(booking.starts_at))
      await this.loadAvailability(`Запись создана: ${formatted} (Москва).`)
    } catch (error) {
      if (error instanceof ApiError && error.status === 409) {
        await this.loadAvailability("Это время уже занято. Выберите другой слот.")
      } else {
        this.bookingStatusTarget.textContent = "Не удалось создать запись. Обновите доступность и попробуйте ещё раз."
        this.bookingRetryTarget.classList.remove("d-none")
      }
    } finally {
      this.submitting = false
      this.controlsTarget.disabled = false
    }
  }
}
