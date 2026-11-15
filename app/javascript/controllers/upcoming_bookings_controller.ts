import { Controller } from "@hotwired/stimulus"
import { DefaultService } from "../generated"
import type { Booking } from "../generated"

export default class extends Controller {
  static targets = ["status", "list", "retry"]
  declare readonly statusTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly retryTarget: HTMLButtonElement

  connect() {
    this.load()
  }

  async load() {
    this.statusTarget.textContent = "Загрузка предстоящих записей…"
    this.retryTarget.classList.add("d-none")
    this.listTarget.replaceChildren()
    try {
      const { data } = await DefaultService.listUpcomingBookings()
      this.statusTarget.textContent = data.length ? "" : "Предстоящих записей пока нет"
      data.forEach((booking) => this.renderBooking(booking))
    } catch {
      this.statusTarget.textContent = "Не удалось загрузить предстоящие записи. Попробуйте ещё раз."
      this.retryTarget.classList.remove("d-none")
    }
  }

  renderBooking(booking: Booking) {
    const item = document.createElement("li")
    item.className = "list-group-item p-3"
    const title = document.createElement("h3")
    title.className = "h6 fw-bold"
    title.textContent = booking.event_type.name
    const format = new Intl.DateTimeFormat("ru-RU", { timeZone: "Europe/Moscow", dateStyle: "short", timeStyle: "short" })
    const time = document.createElement("p")
    time.className = "mb-0 text-secondary"
    time.textContent = `${format.format(new Date(booking.starts_at))} – ${format.format(new Date(booking.ends_at))} (Москва)`
    item.append(title, time)
    this.listTarget.append(item)
  }
}
