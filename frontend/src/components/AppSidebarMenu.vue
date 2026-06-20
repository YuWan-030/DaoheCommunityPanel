<script setup lang="ts">
import {
  useHeaderMenus,
  type SidebarAppDropdownEntry,
  type SidebarEntry
} from "@/hooks/useHeaderMenus";
import { useAppConfigStore } from "@/stores/useAppConfigStore";
import {
  ApartmentOutlined,
  AppstoreOutlined,
  AreaChartOutlined,
  LinkOutlined,
  LoginOutlined,
  MenuOutlined,
  SettingOutlined,
  ShopOutlined,
  ShoppingOutlined,
  TeamOutlined,
  UserOutlined
} from "@ant-design/icons-vue";
import type { Key } from "ant-design-vue/es/table/interface";
import type { Component } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();
const { sidebarItems, handleToPage } = useHeaderMenus();
const { logoImage } = useAppConfigStore();

/** Whether route menu item is active (current path equals or is child of this path) */
const isRouteActive = (path: string): boolean => {
  if (route.path === path) return true;
  if (path === "/") return false;
  return route.path.startsWith(path + "/");
};

/** Sidebar icon for each route path */
const routePathIcons: Record<string, Component> = {
  "/instances": AppstoreOutlined,
  "/market": ShopOutlined,
  "/overview": AreaChartOutlined,
  "/users": TeamOutlined,
  "/node": ApartmentOutlined,
  "/settings": SettingOutlined,
  "/customer": UserOutlined,
  "/login": LoginOutlined,
  "/shop": ShoppingOutlined,
  "/_open_page": LinkOutlined
};

const getRouteIcon = (path: string): Component => {
  return routePathIcons[path] ?? MenuOutlined;
};

const getItemKey = (entry: SidebarEntry, index: number): string => {
  if (entry.type === "divider") return "sidebar-divider";
  if (entry.type === "route") return entry.path;
  return `app-${index}-${entry.title}`;
};

const onAppDropdownClick = (item: SidebarAppDropdownEntry, info: { key: Key }) => {
  item.click(String(info.key));
};
</script>

<template>
  <aside class="left-sidebar">
    <a href="." class="logo">
      <img :src="logoImage" />
    </a>
    <nav class="sidebar-menu">
      <template v-for="(entry, index) in sidebarItems" :key="getItemKey(entry, index)">
        <!-- Divider -->
        <div v-if="entry.type === 'divider'" class="sidebar-divider" />

        <!-- Route link -->
        <a
          v-else-if="entry.type === 'route'"
          class="sidebar-item"
          :class="[entry.customClass, { 'sidebar-item-active': isRouteActive(entry.path) }]"
          @click.prevent="handleToPage(entry.path)"
        >
          <component :is="getRouteIcon(entry.path)" class="sidebar-item-icon" />
          <span class="sidebar-item-text">{{ entry.name }}</span>
        </a>

        <!-- App menu (dropdown) -->
        <a-dropdown v-else-if="entry.type === 'app-dropdown'" trigger="click" placement="topRight">
          <a class="sidebar-item" @click.prevent>
            <component :is="entry.icon" v-if="entry.icon" class="sidebar-item-icon" />
            <span class="sidebar-item-text">{{ entry.title }}</span>
          </a>
          <template #overlay>
            <a-menu @click="(info) => onAppDropdownClick(entry, info)">
              <a-menu-item v-for="m in entry.menus" :key="String(m.value)">
                {{ m.title }}
              </a-menu-item>
            </a-menu>
          </template>
        </a-dropdown>

        <!-- App menu (single click) -->
        <a
          v-else-if="entry.type === 'app'"
          class="sidebar-item"
          :class="entry.customClass"
          @click.prevent="entry.click()"
        >
          <component :is="entry.icon" v-if="entry.icon" class="sidebar-item-icon" />
          <span class="sidebar-item-text">{{ entry.title }}</span>
        </a>
      </template>
    </nav>
  </aside>
</template>

<style lang="scss" scoped>
.logo {
  display: block;
  text-align: center;
  padding-top: 10px;
  padding-bottom: 18px;
  img {
    width: 176px;
    height: 34px;
    object-fit: contain;
    animation: MasterLogoWobble 10s ease infinite;
  }
}

.left-sidebar:hover {
  width: 246px;
}

.left-sidebar {
  display: flex;
  flex-direction: column;
  flex: 0 0 240px;
  text-align: left;
  border-right: 1px solid rgba(236, 164, 82, 0.22);
  background:
    linear-gradient(160deg, rgba(236, 164, 82, 0.16), rgba(47, 162, 147, 0.08) 46%, transparent 72%),
    linear-gradient(180deg, #31191f 0%, #1b171c 100%);
  padding: 20px 12px;
  transition: all 0.3s ease;
  box-shadow: 8px 0 24px rgba(40, 12, 14, 0.16);
}

.sidebar-menu {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  padding: 8px;
  color: rgba(246, 238, 227, 0.82);
  flex: 1;
  gap: 8px;
  width: 100%;
  overflow-y: auto;
}

.sidebar-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 32px 12px 20px;
  color: inherit;
  text-decoration: none;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.4s ease;
  width: 100%;
  border: 1px solid transparent;

  &:hover {
    background-color: rgba(255, 240, 214, 0.1);
    border-color: rgba(236, 164, 82, 0.2);
    color: #fff6e8;
  }

  &.sidebar-item-active {
    background: linear-gradient(135deg, rgba(236, 164, 82, 0.24), rgba(200, 58, 60, 0.18));
    border-color: rgba(236, 164, 82, 0.34);
    color: #ffffff;
    box-shadow: inset 3px 0 0 rgba(236, 164, 82, 0.9);
  }

  .sidebar-item-icon {
    font-size: 16px;
    flex-shrink: 0;
  }

  .sidebar-item-text {
    font-size: 14px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
  }
}

.sidebar-divider {
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(236, 164, 82, 0.28), transparent);
  margin: 12px 0;
  flex-shrink: 0;
  width: 100%;
}

/* Same semantic highlight as AppHeader */
:deep(.nav-button-warning:hover) {
  background-color: rgba(236, 164, 82, 0.2) !important;
  color: #ffe7b5 !important;
}

:deep(.nav-button-success:hover) {
  background-color: rgba(47, 162, 147, 0.18) !important;
  color: #d2fff6 !important;
}

:deep(.nav-button-danger:hover) {
  background-color: rgba(200, 58, 60, 0.28) !important;
  color: #ffe0de !important;
}

@keyframes MasterLogoWobble {
  62% {
    transform: rotate(0deg);
  }
  75% {
    transform: rotate(4deg);
  }
  88% {
    transform: rotate(-4deg);
  }
  100% {
    transform: rotate(0deg);
  }
}
</style>
