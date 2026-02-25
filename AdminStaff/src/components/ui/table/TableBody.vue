<script setup lang="ts">
import { cn } from '@/lib/utils'
defineProps<{ class?: any }>()
</script>

<template>
  <tbody :class="cn('[&_tr:last-child]:border-0', $props.class)">
    <slot />
  </tbody>
</template>
