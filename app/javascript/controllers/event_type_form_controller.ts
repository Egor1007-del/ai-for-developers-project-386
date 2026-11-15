import { Controller } from "@hotwired/stimulus"
import { ApiError, DefaultService, OpenAPI } from "../generated"
import type { ErrorBody } from "../generated"

export default class extends Controller<HTMLFormElement> {
  static targets = ["name", "description", "duration", "nameError", "descriptionError", "durationError", "status", "submit"]
  declare readonly nameTarget: HTMLInputElement
  declare readonly descriptionTarget: HTMLTextAreaElement
  declare readonly durationTarget: HTMLSelectElement
  declare readonly nameErrorTarget: HTMLElement
  declare readonly descriptionErrorTarget: HTMLElement
  declare readonly durationErrorTarget: HTMLElement
  declare readonly statusTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement

  async submit(event: Event) {
    event.preventDefault()
    this.nameErrorTarget.textContent = ""
    this.descriptionErrorTarget.textContent = ""
    this.durationErrorTarget.textContent = ""
    this.statusTarget.textContent = ""
    this.submitTarget.disabled = true
    OpenAPI.HEADERS = { "X-CSRF-Token": document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "" }
    try {
      await DefaultService.createEventType({
        name: this.nameTarget.value,
        description: this.descriptionTarget.value,
        duration_minutes: Number(this.durationTarget.value) as 15 | 30,
      })
      const turbo = (window as Window & { Turbo?: { visit: (url: string) => void } }).Turbo
      const url = this.element.dataset.successUrl ?? "/booking"
      if (turbo) turbo.visit(url)
      else window.location.assign(url)
    } catch (error) {
      if (error instanceof ApiError && error.status === 422) {
        const fields = (error.body as ErrorBody).error.fields
        this.nameErrorTarget.textContent = fields?.name?.join(", ") ?? ""
        this.descriptionErrorTarget.textContent = fields?.description?.join(", ") ?? ""
        this.durationErrorTarget.textContent = fields?.duration_minutes?.join(", ") ?? ""
        this.statusTarget.textContent = "Проверьте поля формы"
      } else {
        this.statusTarget.textContent = "Не удалось создать тип события. Попробуйте ещё раз."
      }
    } finally {
      this.submitTarget.disabled = false
    }
  }
}
