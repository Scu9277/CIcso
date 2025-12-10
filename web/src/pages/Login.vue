<template>
  <div class="premium-login">
    <!-- Background -->
    <div class="background-layer"></div>
    
    <!-- Main Container -->
    <div class="login-container">
      <!-- Left Branding Section -->
      <div class="branding-section">
        <div class="branding-content">
          <div class="logo-mark">
            <svg viewBox="0 0 48 48" class="logo-icon">
              <circle cx="24" cy="24" r="20" fill="none" stroke="currentColor" stroke-width="2"/>
              <path d="M24 14 L24 24 L30 30" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </div>
          <h1 class="brand-name">Scu SSLVPN</h1>
          <p class="brand-tagline">Enterprise Secure Access Platform</p>
          
          <div class="features-list">
            <div class="feature">
              <div class="feature-icon">✓</div>
              <span>零信任网络访问</span>
            </div>
            <div class="feature">
              <div class="feature-icon">✓</div>
              <span>端到端加密传输</span>
            </div>
            <div class="feature">
              <div class="feature-icon">✓</div>
              <span>多因素身份认证</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Right Login Form Section -->
      <div class="form-section">
        <div class="form-card">
          <div class="form-header">
            <h2>管理员登录</h2>
            <p>Sign in to continue to management portal</p>
          </div>
          
          <el-form :model="ruleForm" :rules="rules" ref="ruleForm" class="login-form">
            <el-form-item prop="admin_user">
              <label class="input-label">用户名</label>
              <el-input 
                v-model="ruleForm.admin_user" 
                placeholder="请输入管理员账号"
                class="premium-input">
                <i slot="prefix" class="el-icon-user"></i>
              </el-input>
            </el-form-item>
            
            <el-form-item prop="admin_pass">
              <label class="input-label">密码</label>
              <el-input 
                type="password" 
                v-model="ruleForm.admin_pass" 
                autocomplete="off" 
                placeholder="请输入管理员密码"
                class="premium-input">
                <i slot="prefix" class="el-icon-lock"></i>
              </el-input>
            </el-form-item>
            
            <el-button 
              type="primary" 
              :loading="isLoading" 
              @click="submitForm('ruleForm')" 
              class="submit-button">
              {{ isLoading ? '登录中...' : '登录' }}
            </el-button>
          </el-form>
          
          <div class="form-footer">
            <p>© {{ new Date().getFullYear() }} Scu SSLVPN. All rights reserved.</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import axios from "axios";
import qs from "qs";
import {setToken, setUser} from "@/plugins/token";

export default {
  name: "Login",
  mounted() {
    console.log("login created")
    window.addEventListener('keydown', this.keyDown);
  },
  destroyed(){
    window.removeEventListener('keydown',this.keyDown,false);
  },
  data() {
    return {
      isLoading: false,
      ruleForm: {
        admin_user: '',
        admin_pass: ''
      },
      rules: {
        admin_user: [
          {required: true, message: '请输入用户名', trigger: 'blur'},
          {max: 50, message: '长度小于 50 个字符', trigger: 'blur'}
        ],
        admin_pass: [
          {required: true, message: '请输入密码', trigger: 'blur'},
          {min: 6, message: '长度大于 6 个字符', trigger: 'blur'}
        ],
      },
    }
  },
  methods: {
    keyDown(e) {
      if (e.keyCode === 13) {
        this.submitForm('ruleForm');
      }
    },
    submitForm(formName) {
      this.$refs[formName].validate((valid) => {
        if (!valid) {
          return false;
        }
        this.isLoading = true
        axios.post('/base/login', qs.stringify(this.ruleForm)).then(resp => {
          var rdata = resp.data
          if (rdata.code === 0) {
            this.$message.success(rdata.msg);
            setToken(rdata.data.token)
            setUser(rdata.data.admin_user)
            this.$router.push("/home");
          } else {
            this.$message.error(rdata.msg);
          }
        }).catch(error => {
          this.$message.error('请求出错');
          console.log(error);
        }).finally(() => {
          this.isLoading = false
        });
      });
    },
  },
}
</script>

<style scoped>
/* Premium Login Design - Apple/Cisco/Google Inspired */

.premium-login {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  background: #fafafa;
}

.background-layer {
  position: absolute;
  width: 100%;
  height: 100%;
  background: linear-gradient(135deg, #f5f7fa 0%, #e8edf2 100%);
}

.login-container {
  position: relative;
  display: flex;
  height: 100%;
  max-width: 1200px;
  margin: 0 auto;
  z-index: 1;
}

/* Branding Section */
.branding-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 80px 60px;
  animation: fadeInLeft 0.6s ease-out;
}

@keyframes fadeInLeft {
  from {
    opacity: 0;
    transform: translateX(-20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.branding-content {
  max-width: 420px;
}

.logo-mark {
  width: 64px;
  height: 64px;
  margin-bottom: 32px;
}

.logo-icon {
  width: 100%;
  height: 100%;
  color: #2c5aa0;
}

.brand-name {
  font-size: 42px;
  font-weight: 600;
  color: #1a1a1a;
  margin-bottom: 12px;
  letter-spacing: -0.5px;
}

.brand-tagline {
  font-size: 18px;
  color: #666;
  margin-bottom: 48px;
  font-weight: 400;
}

.features-list {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.feature {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 15px;
  color: #444;
}

.feature-icon {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #2c5aa0;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 600;
}

/* Form Section */
.form-section {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 80px 60px;
}

.form-card {
  width: 100%;
  max-width: 420px;
  background: white;
  border-radius: 16px;
  padding: 48px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.06);
  animation: fadeInRight 0.6s ease-out;
}

@keyframes fadeInRight {
  from {
    opacity: 0;
    transform: translateX(20px);
  }
  to {
    opacity: 1;
    transform: translateX(0);
  }
}

.form-header {
  margin-bottom: 40px;
}

.form-header h2 {
  font-size: 28px;
  font-weight: 600;
  color: #1a1a1a;
  margin-bottom: 8px;
  letter-spacing: -0.3px;
}

.form-header p {
  font-size: 14px;
  color: #888;
  font-weight: 400;
}

/* Form Styling */
.login-form .el-form-item {
  margin-bottom: 28px;
}

.input-label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #444;
  margin-bottom: 8px;
}

::v-deep .premium-input .el-input__inner {
  height: 48px;
  border: 1.5px solid #e0e0e0;
  border-radius: 10px;
  padding-left: 44px;
  font-size: 15px;
  transition: all 0.2s ease;
  background: #fafafa;
}

::v-deep .premium-input .el-input__inner:focus {
  border-color: #2c5aa0;
  background: white;
  box-shadow: 0 0 0 3px rgba(44, 90, 160, 0.08);
}

::v-deep .premium-input .el-input__prefix {
  left: 14px;
  color: #888;
}

.submit-button {
  width: 100%;
  height: 48px;
  font-size: 15px;
  font-weight: 600;
  background: #2c5aa0;
  border: none;
  border-radius: 10px;
  margin-top: 12px;
  transition: all 0.2s ease;
}

.submit-button:hover {
  background: #234a87;
  transform: translateY(-1px);
  box-shadow: 0 8px 16px rgba(44, 90, 160, 0.2);
}

.submit-button:active {
  transform: translateY(0);
}

.form-footer {
  margin-top: 40px;
  text-align: center;
}

.form-footer p {
  font-size: 13px;
  color: #999;
}

/* Responsive */
@media (max-width: 1024px) {
  .branding-section {
    display: none;
  }
  
  .form-section {
    flex: 1 1 100%;
  }
}
</style>