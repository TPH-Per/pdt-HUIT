<script setup lang="ts" generic="TData, TValue">
import {
  FlexRender,
  getCoreRowModel,
  useVueTable,
  getPaginationRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  type SortingState,
  type ColumnDef,
} from '@tanstack/vue-table'
import Table from '@/components/ui/table/Table.vue'
import TableBody from '@/components/ui/table/TableBody.vue'
import TableCell from '@/components/ui/table/TableCell.vue'
import TableHead from '@/components/ui/table/TableHead.vue'
import TableHeader from '@/components/ui/table/TableHeader.vue'
import TableRow from '@/components/ui/table/TableRow.vue'
import TableEmpty from '@/components/ui/table/TableEmpty.vue'
import Button from '@/components/ui/button/Button.vue'
import Input from '@/components/ui/input/Input.vue'
import { ref } from 'vue'
import { ArrowUpDown, Search, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight } from 'lucide-vue-next'

const props = defineProps<{
  columns: ColumnDef<TData, TValue>[]
  data: TData[]
  searchPlaceholder?: string
}>()

const sorting = ref<SortingState>([])
const globalFilter = ref('')

const table = useVueTable({
  get data() { return props.data },
  get columns() { return props.columns },
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
  state: {
    get sorting() { return sorting.value },
    get globalFilter() { return globalFilter.value },
  },
  onSortingChange: updaterOrValue => {
    sorting.value = typeof updaterOrValue === 'function' ? updaterOrValue(sorting.value) : updaterOrValue
  },
  onGlobalFilterChange: (updaterOrValue) => {
     globalFilter.value = typeof updaterOrValue === 'function' ? updaterOrValue(globalFilter.value) : updaterOrValue
  }
})
</script>

<template>
  <div class="space-y-4">
    <!-- Filter -->
    <div class="flex items-center gap-2">
       <div class="relative max-w-sm w-full">
           <Search class="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
           <Input
              type="text"
              class="pl-9"
              :placeholder="searchPlaceholder || 'Tìm kiếm...'"
              :model-value="globalFilter"
              @update:model-value="val => globalFilter = String(val)"
           />
       </div>
    </div>

    <!-- Table -->
    <div class="rounded-md border bg-white shadow-sm overflow-hidden">
      <Table>
        <TableHeader class="bg-gray-50/50">
          <TableRow v-for="headerGroup in table.getHeaderGroups()" :key="headerGroup.id" class="hover:bg-transparent">
            <TableHead v-for="header in headerGroup.headers" :key="header.id">
              <div v-if="!header.isPlaceholder" 
                   class="flex items-center gap-1.5"
                   :class="{ 'cursor-pointer select-none hover:text-foreground': header.column.getCanSort() }"
                   @click="header.column.getToggleSortingHandler()?.($event)"
              >
                <FlexRender :render="header.column.columnDef.header" :props="header.getContext()" />
                <ArrowUpDown v-if="header.column.getCanSort()" class="h-3 w-3 text-muted-foreground/60" />
              </div>
            </TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <template v-if="table.getRowModel().rows?.length">
            <TableRow
              v-for="row in table.getRowModel().rows"
              :key="row.id"
              :data-state="row.getIsSelected() ? 'selected' : undefined"
              class="group"
            >
              <TableCell v-for="cell in row.getVisibleCells()" :key="cell.id" class="py-3">
                <FlexRender :render="cell.column.columnDef.cell" :props="cell.getContext()" />
              </TableCell>
            </TableRow>
          </template>
          <TableEmpty v-else :colspan="columns.length">
             <div class="flex flex-col items-center justify-center py-6 text-muted-foreground">
                <p>Không tìm thấy dữ liệu phù hợp</p>
             </div>
          </TableEmpty>
        </TableBody>
      </Table>
    </div>

    <!-- Pagination -->
    <div class="flex items-center justify-between px-2 py-2 border-t mt-0">
       <div class="text-sm text-gray-500">
          Hiển thị trang <span class="font-medium text-gray-900">{{ table.getState().pagination.pageIndex + 1 }}</span> 
          trên <span class="font-medium text-gray-900">{{ table.getPageCount() }}</span>
          <span class="mx-2 text-gray-300">|</span>
          Tổng cộng <span class="font-medium text-gray-900">{{ table.getFilteredRowModel().rows.length }}</span> kết quả
       </div>
       
       <div class="flex items-center space-x-2">
         <div class="flex items-center space-x-1">
            <Button
              variant="outline"
              size="icon"
              :disabled="!table.getCanPreviousPage()"
              @click="table.setPageIndex(0)"
              class="h-8 w-8 p-0"
              title="Trang đầu"
            >
              <ChevronsLeft class="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              :disabled="!table.getCanPreviousPage()"
              @click="table.previousPage()"
              class="h-8 w-8 p-0"
              title="Trang trước"
            >
              <ChevronLeft class="h-4 w-4" />
            </Button>
         </div>
         
         <div class="text-sm font-medium w-[80px] text-center">
            Trang {{ table.getState().pagination.pageIndex + 1 }}/{{ table.getPageCount() }}
         </div>

         <div class="flex items-center space-x-1">
            <Button
              variant="outline"
              size="icon"
              :disabled="!table.getCanNextPage()"
              @click="table.nextPage()"
              class="h-8 w-8 p-0"
              title="Trang sau"
            >
              <ChevronRight class="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              :disabled="!table.getCanNextPage()"
              @click="table.setPageIndex(table.getPageCount() - 1)"
              class="h-8 w-8 p-0"
              title="Trang cuối"
            >
              <ChevronsRight class="h-4 w-4" />
            </Button>
         </div>
       </div>
    </div>
  </div>
</template>
