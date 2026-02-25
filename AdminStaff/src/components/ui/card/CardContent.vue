<script setup lang="ts">
import { cn } from '@/lib/utils'
defineProps<{ class?: any }>()
</script>
<template>
  <div :class="cn('p-6 pt-0', $props.class)">
    <slot />
  </div>
</template>
