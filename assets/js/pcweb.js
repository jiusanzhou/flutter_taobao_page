// webflow library for javascript
((_, document) => {

    const _get = (obj, key) => {
        return obj?obj[key]:null
    }

    const ACTION_FLUSH = "flush"
    const ACTION_CONTINUE = "continue"

    // 返回json字符串
    const json = (data) => JSON.stringify(data)
    
    // 返回结构化数据
    const resp = (data, error=null, next=null, action=null) => json({ error, data, next, action })

    // 检查是否有验证码
    _check_verify_code = () => {
        // 检查是否有验证码 TODO: 现在只检查了订单页
        let orders = document.querySelectorAll('.js-order-container')
        return orders.length === 0 ? resp(null, "验证码") : null
    }
    
    // 抓取订单
    _mtb_fetch_order = (page = 1) => {
        let r = new XMLHttpRequest()
        r.open(
            'POST',
            'https://buyertrade.taobao.com/trade/itemlist/asyncBought.htm?action=itemlist/BoughtQueryAction&event_submit_do_query=1&_input_charset=utf8',
            null
        )
        r.setRequestHeader('content-type', 'application/x-www-form-urlencoded; charset=UTF-8')
        r.send(`pageNum=${page}&pageSize=10}`)
        if ( r.status === 200 ) {
            return JSON.parse(r.responseText)
        }
        return null
    }

    // 重置viewport
    _._mresetviewport = () => {
        let _meta = document.querySelector('head > meta[name=viewport]')
        if ( _meta ) _meta.setAttribute('content', '')
    }

    // 登录页(h5)
    _._mlogin = () => {
        return resp(__mtb, "无需执行任务")
    }
    
    // 个人主页(h5)
    _._mhome = () => {
        let tmp = document.querySelector('body > div.page-container > div.main-layout > div:nth-child(1) > div > div:nth-child(2)')
        if ( !tmp ) return resp({})
        let data = {
            nickname: _get(tmp.querySelector('span'), 'textContent'),
            logo: tmp.querySelector('div:nth-child(1) > div > div').style.backgroundImage.slice(5, -2),
        }
        return resp(data)
    }

    // 个人基础信息(头像，暱称；inapp在android 上无法打开h5的个人主页)
    _._mbaseinfo = () => {
        let _tmp_nick = document.querySelector('#J_uniqueName')
        let _tmp_logo = document.querySelector('a.pf-avatar > img')
        let data = {
            nickname: _tmp_nick?_tmp_nick.value:null,
            logo: _tmp_logo?_tmp_logo.src:null,
        }
        return resp(data)
    }
    
    // 个人基础信息
    _._mprofile = () => {
        let tmp = document.querySelector('#ah\\:addressForm')
        if ( !tmp ) return resp(null, "查询DOM节点失败")
        let _score = document.querySelector('.tao-score')
        let data = {
            tao_score: _score?_score.innerText:null,
            realname: tmp.querySelector('li:nth-child(1) > strong').innerText,
            email: tmp.querySelector('li:nth-child(2) > strong').innerText,
            gender: tmp.querySelector('li:nth-child(3) > input[type=hidden]').getAttribute('value'),
            birth: Array.from(tmp.querySelectorAll('li:nth-child(4) > input')).map(i=>i.value).join('-'),
            avatar: document.querySelector('#J_MtAvatarBox > a > img').src,
        }
        return resp(data)
    }
    
    // 账户安全信息
    _._msecurity = () => {
        let data = {}
        Array.from(document.querySelectorAll('#main-content > dl > dd:nth-child(2) > ul > li')).map(i => {
            if (!i) return
            data[_get(i.querySelector('span:nth-child(1)'), 'innerText')] = _get(i.querySelector('span:nth-child(2)'), 'innerText')
        })
        return resp(data)
    }
    
    // 实名认证信息
    _._mcertify = () => {
        let tmps = document.querySelectorAll('#main-content > div > div.certify-info > div.msg-box-content > .explain-info')
        let _score = document.querySelector('.tao-score')
        let data = {
            tao_score: _score?_score.innerText:null,
            idcard_infos: Array.from(tmps).map(i => i.innerText),
        }
        return resp(data)
    }
    
    // 淘气值
    _._mrate_prepare = () => {
        document.querySelector('#J_SiteNavLogin > div.site-nav-menu-hd > div.site-nav-user > span').click()
        document.querySelector('#J_SiteNavLogin').dispatchEvent(new MouseEvent('mouseover', {'view': window, 'bubbles': true, 'cancelable': true }))
    }

    _._mscore = () => {
        let r = new XMLHttpRequest()
        r.open(
            'GET',
            'https://vip.taobao.com/ajax/getGoldUser.do?_input_charset=utf-8&from=diaoding',
            null
        )
        r.send(null)
        if ( r.status === 200 ) {
            let res = JSON.parse(r.responseText)
            return resp(res.data)
        }
        let data = {
            code: r.status,
            status: r.statusText,
            text: r.responseText
        }
        return resp(data)
    }

    _._mrate = () => {

        let buyertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-buyer')
        let sellertmp = document.querySelector('#new-rate-content > div.clearfix.personal-info > div.personal-rating > h4.tb-rate-ico-bg.ico-seller')

        let _score = document.querySelector('.tao-score')
        let data = {
            buyer: {
                tao_score: _score?_score.innerText:null,
                summary: buyertmp.querySelector('a:nth-child(1)').innerText,
                rankimg: buyertmp.querySelector('a:nth-child(2) > img').src,
                ratings: Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table.tb-rate-table.align-c.thm-plain > tbody > tr')).map(i => Array.from(i.querySelectorAll('td')).map(i => i.innerText)),
            },
        }

        if (sellertmp) {
            data.seller = {
                summary: sellertmp.querySelector('a:nth-child(1)').innerText,
                rankimg: sellertmp.querySelector('img').src,
            }
            data.buyer.ratings = Array.from(document.querySelectorAll('#new-rate-content > div.clearfix.personal-info > div.personal-rating > table:nth-child(8) > tbody > tr')).map(i => Array.from(i.querySelectorAll('td')).map(i => i.innerText))
        }
        return resp(data)
    }
    
    // 退款管理
    _._mdispute = () => {
        let keys = Object.keys(disputeData.data||{}).filter(i => i.indexOf('disputeListGrid') === 0)
        let data = {
            orders: keys.map(i=>disputeData.data[i])
        }
        return resp(data, null, null, ACTION_FLUSH)
    }

    // 信誉评级
    _._mapass = () => {
        let data = {
            star: document.querySelector('span.star').innerText,
        }
        return resp(data)
    }

    // 收获地址
    _._maddress = () => {
        let tmps = document.querySelectorAll('#container > div > div.addressList > div.next-table > table > tbody > tr')
        let data = {
            address: Array.from(tmps).map(i => Array.from(i.querySelectorAll('td')).map(i => i.innerText).slice(0, -2))
        }
        return resp(data)
    }
    
    // 订单列表
    _.__mtb_order_current = 1
    _._morder = () => {
        let _r = _check_verify_code()
        if (_r) return _r
        // TODO: 请求订单
        let data = _mtb_fetch_order(_.__mtb_order_current)
        return resp({page: _.__mtb_order_current++, data}, null, null, ACTION_CONTINUE)
    }
    
    return "webflow.lib.js 安装成功"
})(window, document)