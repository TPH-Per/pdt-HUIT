<script setup lang="ts">
import { cn } from '@/lib/utils'
defineProps<{ class?: any, colspan?: number }>()
</script>

<template>
  <tr :class="cn('hover:bg-transparent', $props.class)">
    <td :colspan="colspan || 100" class="p-8 text-center text-muted-foreground whitespace-nowrap align-middle h-24">
      <slot />
    </td>
  </tr>
</template>
