package employeesmanagement.common;

import java.util.List;

public class Page<T> {

	private List<T> content;
    private int pageNumber;
    private int pageSize;
    private int totalElements;
    private int totalPages;

    public Page(List<T> content, int pageNumber, int pageSize, int totalElements, int totalPages) {
        this.content = content;
        this.pageNumber = pageNumber;
        this.pageSize = pageSize;
        this.totalElements = totalElements;
        this.totalPages = totalPages;
    }

    public List<T> getContent() {
        return content;
    }

    public int getPageNumber() {
        return pageNumber;
    }

    public int getPageSize() {
        return pageSize;
    }

    public int getTotalElements() {
        return totalElements;
    }

    public int getTotalPages() {
        return totalPages;
    }
}