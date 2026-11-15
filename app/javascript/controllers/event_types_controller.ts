import { Controller } from "@hotwired/stimulus"
import { ApiError, DefaultService, OpenAPI } from "../generated"
import type { Day, EventType, Slot } from "../generated"

export default class extends Controller {
  static targets = ["status", "list", "retry", "create", "types", "booking", "heading", "eventName", "description", "duration", "selectedDate", "month", "previous", "next", "bookingStatus", "bookingRetry", "days", "slots", "selection", "confirm", "controls"]
  declare readonly typesTarget: HTMLElement
  declare readonly eventNameTarget: HTMLElement
  declare readonly descriptionTarget: HTMLElement
  declare readonly durationTarget: HTMLElement
  declare readonly selectedDateTarget: HTMLElement
  declare readonly monthTarget: HTMLElement
  declare readonly previousTarget: HTMLButtonElement
  declare readonly nextTarget: HTMLButtonElement
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
  private availability: Day[] = []
  private month = ""
  private selectedDay?: Day

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
      this.headingTarget.textContent = eventType.name
      this.eventNameTarget.textContent = eventType.name
      this.descriptionTarget.textContent = eventType.description
      this.durationTarget.textContent = `${eventType.duration_minutes} мин`
      this.typesTarget.classList.add("d-none")
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
    this.selectionTarget.textContent = "Время не выбрано"
    this.selectedDateTarget.textContent = "Дата не выбрана"
    this.selectedDay = undefined
    this.daysTarget.replaceChildren()
    this.slotsTarget.replaceChildren()
    this.bookingRetryTarget.classList.add("d-none")
    this.bookingStatusTarget.textContent = "Загрузка доступности…"
    try {
      const availability = await DefaultService.getAvailability(this.selectedType.id)
      if (version !== this.requestVersion) return
      this.bookingStatusTarget.textContent = message || "Выберите дату (московское время)"
      this.availability = availability.days
      this.month = availability.days[0]?.date.slice(0, 7) ?? ""
      this.renderCalendar()
    } catch {
      if (version !== this.requestVersion) return
      this.bookingStatusTarget.textContent = message ? `${message} Не удалось обновить доступность.` : "Не удалось загрузить доступность. Попробуйте ещё раз."
      this.bookingRetryTarget.classList.remove("d-none")
    }
  }

  retryAvailability() {
    this.loadAvailability()
  }

  back() {
    ++this.requestVersion
    this.bookingTarget.classList.add("d-none")
    this.typesTarget.classList.remove("d-none")
  }

  previousMonth() { this.changeMonth(-1) }
  nextMonth() { this.changeMonth(1) }

  changeMonth(direction: number) {
    const date = new Date(`${this.month}-01T00:00:00Z`)
    date.setUTCMonth(date.getUTCMonth() + direction)
    this.month = date.toISOString().slice(0, 7)
    this.renderCalendar()
  }

  renderCalendar() {
    if (!this.month) return
    const date = new Date(`${this.month}-01T00:00:00Z`)
    this.monthTarget.textContent = new Intl.DateTimeFormat("ru-RU", { month: "long", year: "numeric", timeZone: "UTC" }).format(date)
    const months = this.availability.map((day) => day.date.slice(0, 7))
    this.previousTarget.disabled = this.month <= months[0]
    this.nextTarget.disabled = this.month >= months[months.length - 1]
    this.daysTarget.replaceChildren()
    const offset = (date.getUTCDay() + 6) % 7
    for (let i = 0; i < offset; i++) this.daysTarget.append(document.createElement("span"))
    const year = date.getUTCFullYear()
    const month = date.getUTCMonth()
    const count = new Date(Date.UTC(year, month + 1, 0)).getUTCDate()
    for (let i = 1; i <= count; i++) {
      const key = `${this.month}-${String(i).padStart(2, "0")}`
      this.renderDay(key, this.availability.find((day) => day.date === key))
    }
  }

  renderDay(date: string, day?: Day) {
    const button = document.createElement("button")
    button.type = "button"
    button.className = "booking-day"
    button.setAttribute("aria-label", date)
    button.textContent = String(Number(date.slice(8)))
    button.disabled = !day || day.slots.length === 0
    if (day?.slots.length) {
      const count = document.createElement("small")
      count.textContent = `${day.slots.length} св.`
      button.append(count)
    }
    if (this.selectedDay?.date === date) button.classList.add("is-selected")
    button.addEventListener("click", () => {
      if (!day) return
      this.selectedDay = day
      this.selectedDateTarget.textContent = new Intl.DateTimeFormat("ru-RU", { weekday: "long", day: "numeric", month: "long", timeZone: "UTC" }).format(new Date(`${day.date}T00:00:00Z`))
      this.selectedSlot = undefined
      this.selectionTarget.textContent = "Время не выбрано"
      this.confirmTarget.classList.add("d-none")
      this.slotsTarget.replaceChildren()
      this.renderCalendar()
      const slots = [...day.slots.map((slot) => ({ slot, busy: false })), ...day.busy_slots.map((slot) => ({ slot, busy: true }))]
      slots.sort((a, b) => a.slot.starts_at.localeCompare(b.slot.starts_at))
      slots.forEach(({ slot, busy }) => {
        const time = document.createElement("button")
        time.type = "button"
        time.className = "booking-slot"
        time.disabled = busy
        const format = (value: string) => new Intl.DateTimeFormat("ru-RU", { timeZone: "Europe/Moscow", hour: "2-digit", minute: "2-digit" }).format(new Date(value))
        const label = `${format(slot.starts_at)} - ${format(slot.ends_at)}`
        const text = document.createElement("span")
        text.textContent = `${label} `
        const status = document.createElement("strong")
        status.textContent = busy ? "Занято" : "Свободно"
        time.append(text, status)
        time.addEventListener("click", () => {
          this.selectedSlot = slot
          this.slotsTarget.querySelectorAll(".is-selected").forEach((element) => element.classList.remove("is-selected"))
          time.classList.add("is-selected")
          this.selectionTarget.textContent = `Выбрано: ${day.date}, ${format(slot.starts_at)} (Москва)`
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
