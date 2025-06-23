package employeesmanagement.presentation.api.servlets.config;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import com.google.gson.TypeAdapter;
import com.google.gson.stream.JsonReader;
import com.google.gson.stream.JsonWriter;

public class GsonLocalDateAdapter extends TypeAdapter<LocalDate> {
    
	private static final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE;

    @Override
    public void write(JsonWriter writer, LocalDate value) throws IOException {
        writer.value(value.format(formatter));
    }

    @Override
    public LocalDate read(JsonReader reader) throws IOException {
        return LocalDate.parse(reader.nextString(), formatter);
    }
}
