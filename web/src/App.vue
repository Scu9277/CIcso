<template>
  <div id="app">
    <router-view></router-view>
  </div>
</template>

<script>

export default {
  name: 'app',
  components: {},
  created() {
    const token = sessionStorage.getItem('jwtToken');
    console.log("App created", token)
    if (token) {
      this.$root.isLogin = true
    }
  },
  mounted() {
    console.log("App mounted")
  },
  data() {
    return {}
  },
  computed: {
    currentComponent: function () {
      var isLogin = this.$root.isLogin
      console.log("App isLogin", isLogin)
      if (isLogin) {
        return "layout";
      }
      return "login";
    },
  },
}
</script>

<style>
html, body {
  height: 100%;
  margin: 0;
}

#app {
  font-family: "Helvetica Neue", Helvetica, "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "微软雅黑", Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  /*color: #2c3e50;*/
  /*border: 1px solid red;*/
  height: 100%;
  /*width:100%;*/
  /*box-sizing: border-box;*/
  /*padding: 4px;*/
}

.hide {
  display: none;
}

/*space vertical*/
.sh-10 {
  height: 10px;
}

.sh-20 {
  height: 20px;
}

/*space horizontal*/
.sw-10 {
  height: 1px;
  width: 10px;
}

.sw-20 {
  height: 1px;
  width: 20px;
}



.m-left-10 {
  margin-left: 10px;
}

/* ============================================ */
/* Premium Design System - Apple/Cisco/Google Inspired */
/* ============================================ */

/* Cards - Clean & Elegant */
.el-card {
  border-radius: 12px !important;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08) !important;
  border: 1px solid #e8e8e8 !important;
  transition: box-shadow 0.2s ease;
}

.el-card:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.12) !important;
}

.el-card__header {
  border-bottom: 1px solid #f0f0f0 !important;
  background: #fafafa !important;
  font-weight: 600 !important;
  color: #333 !important;
  padding: 18px 20px !important;
}

.el-card__body {
  padding: 20px !important;
}

/* Buttons - Professional */
.el-button--primary {
  background: #2c5aa0 !important;
  border: none !important;
  box-shadow: 0 1px 3px rgba(44, 90, 160, 0.15);
  transition: all 0.2s ease;
}

.el-button--primary:hover {
  background: #234a87 !important;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(44, 90, 160, 0.25) !important;
}

.el-button {
  border-radius: 8px !important;
  font-weight: 500;
  padding: 10px 20px;
}

.el-button--small {
  padding: 8px 16px;
}

/* Tables - Clean & Organized */
.el-table {
  border-radius: 8px !important;
  overflow: hidden;
}

.el-table th {
  background-color: #fafafa !important;
  color: #666;
  font-weight: 600;
  font-size: 13px;
}

.el-table tr:hover > td {
  background-color: #f9f9f9 !important;
}

.el-table td,
.el-table th {
  border-color: #f0f0f0 !important;
}

/* Inputs - Minimal & Clean */
.el-input__inner {
  border-radius: 8px !important;
  border: 1px solid #e0e0e0 !important;
  transition: all 0.2s ease;
  padding: 0 15px;
}

.el-input__inner:focus {
  border-color: #2c5aa0 !important;
  box-shadow: 0 0 0 3px rgba(44, 90, 160, 0.08) !important;
}

.el-input__inner::placeholder {
  color: #999;
}

/* Dialogs - Premium */
.el-dialog {
  border-radius: 16px !important;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.12) !important;
}

.el-dialog__header {
  padding: 24px 24px 16px !important;
  border-bottom: 1px solid #f0f0f0 !important;
}

.el-dialog__title {
  font-size: 18px !important;
  font-weight: 600 !important;
  color: #333 !important;
}

.el-dialog__body {
  padding: 24px !important;
  color: #666;
}

/* Tabs - Clean */
.el-tabs__item {
  font-weight: 500;
  transition: color 0.2s ease;
  font-size: 14px;
}

.el-tabs__item.is-active {
  color: #2c5aa0 !important;
}

.el-tabs__active-bar {
  background-color: #2c5aa0 !important;
  height: 3px !important;
}

/* Pagination - Modern */
.el-pagination .btn-next,
.el-pagination .btn-prev,
.el-pager li {
  border-radius: 6px !important;
  margin: 0 4px;
}

.el-pager li.active {
  background: #2c5aa0 !important;
  color: white !important;
}

/* Message - Polished */
.el-message {
  border-radius: 8px !important;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.10) !important;
  border: 1px solid #e8e8e8;
}

/* Loading */
.el-loading-mask {
  background-color: rgba(255, 255, 255, 0.95) !important;
}

/* Select Dropdown */
.el-select-dropdown {
  border-radius: 8px !important;
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08) !important;
  border: 1px solid #e8e8e8 !important;
}

/* Tag - Clean */
.el-tag {
  border-radius: 6px !important;
  border: 1px solid #e8e8e8 !important;
}

/* Switch - Modern */
.el-switch.is-checked .el-switch__core {
  background-color: #2c5aa0 !important;
  border-color: #2c5aa0 !important;
}

</style>

