import { application } from "./application"
import HelloController from "./hello_controller"
import EventTypesController from "./event_types_controller"
import EventTypeFormController from "./event_type_form_controller"

application.register("hello", HelloController)
application.register("event-types", EventTypesController)
application.register("event-type-form", EventTypeFormController)
