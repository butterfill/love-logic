tree = require('../../tree')
      
describe 'zoxiy', ->
  describe 'counter_ex', ->
    
    it 'clear cache', ->
      base.clearCache(browser)

    it 'login', ->
      base.login(browser)
    
    it 'can reset tester', ->
      base.resetTester(browser)
  
    it 'goes to the page', ->
      base.goPage browser, '/ex/counter/qq/F(a)|F(b)'
        
      msg = browser.getText(xFindText('F(a)'))
      expect(msg).to.exist

    it 'allows you to add to the extension of a predicate', ->
      inputSel = 'input[name=predicate-F]'
      browser.setValue(inputSel, '{<0>}\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).to.equal('{<0>}')

    it 'marks correct answers correct @watch', ->
      browser.click 'button#submit'
      browser.pause 250
      msg = browser.waitForText(xFindText('answer is correct'))
      expect(msg).to.exist

    it 'allows you to add to, and remove from, the domain', ->
      browser.click '.addToDomain'
      expect(browser.getText('.domain').indexOf('1')).not.to.equal(-1)
      browser.click '.removeFromDomain'
      expect(browser.getText('.domain').indexOf('1')).to.equal(-1)

    it 'doesn’t allow removing the last element from the domain', ->
      browser.click '.removeFromDomain'
      browser.click '.removeFromDomain'
      expect(browser.getText('.domain').indexOf('0')).not.to.equal(-1)

    it 'does not allow you to include non-domain objects in extensions', ->
      inputSel = 'input[name=predicate-F]'
      browser.setValue(inputSel, '{<0>,<1>}\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).to.equal('{<0>}')
    
    it 'does not allow you to remove domain objects if they are in extensions', ->
      browser.execute () -> $('#toast-container').hide()
      browser.click '.addToDomain'
      inputSel = 'input[name=predicate-F]'
      browser.setValue(inputSel, '{<0>,<1>}\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).to.equal('{<0>,<1>}')
      browser.click '.removeFromDomain'
      browser.click '.removeFromDomain'
      expect(browser.getText('.domain').indexOf('1')).not.to.equal(-1)

    it 'allows you to update the referents of names', ->
      inputSel = 'input[name=name-a]'
      browser.setValue(inputSel, '1\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).to.equal('1')

    it 'only allows you to assign names to objects in the domain', ->
      inputSel = 'input[name=name-a]'
      browser.setValue(inputSel, '2\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).not.to.equal('2')
    
    it 'marks incorrect answers incorrect', ->
      browser.click '.addToDomain'
      browser.click '.addToDomain'
      inputSel = 'input[name=name-a]'
      browser.setValue(inputSel, '2\t')
      expect(browser.getValue(inputSel).replace(/\s/g,'')).to.equal('2')
      browser.click 'button#submit'
      browser.pause 250
      msg = browser.waitForText(xFindText('answer is incorrect'))
      expect(msg).to.exist
      
    it 'updates the question when changing the page', ->
      browser.execute () ->
        FlowRouter.go '/ex/counter/qq/G(c)|a=c'
      doesntExist = browser.waitForExist(xFindText('F(a)'), 100, true)
      expect(doesntExist).to.be.true
      msg = browser.getText(xFindText('G(c)'))
      expect(msg).to.exist
      msg = browser.getText(xFindText('a=c'))
      expect(msg).to.exist
      return
    return
  return

